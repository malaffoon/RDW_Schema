USE reporting;

CREATE TABLE IF NOT EXISTS iab_validation
(
  id      BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  testNum INT,
  result1 VARCHAR(1000),
  result2 VARCHAR(1000),
  result3 VARCHAR(1000),
  result4 VARCHAR(1000),
  result5 VARCHAR(1000),
  result6 VARCHAR(1000),
  result7 VARCHAR(1000),
  result8 VARCHAR(1000),
  created TIMESTAMP       DEFAULT current_timestamp
);

-- Clear results from previous script executions
DELETE FROM iab_validation;

-- Total counts
INSERT INTO iab_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation) + 1,
    'total_iab';
INSERT INTO iab_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation),
    count(*)
  FROM exam
  WHERE type_id = 2;

INSERT INTO iab_validation (testNum, result1, result2, result3)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation) + 1,
    'total iab score',
    'total std err',
    'total perf level';
INSERT INTO iab_validation (testNum, result1, result2, result3)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation),
    sum(scale_score),
    sum(scale_score_std_err),
    sum(performance_level)
  FROM exam
  WHERE type_id = 2;

-- Exam break down by asmt year, admin condition and complete
INSERT INTO iab_validation (testNum, result1, result2, result3, result4, result5)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation) + 1,
    'iab exams',
    'asmt',
    'asmt year',
    'admin condition',
    'complete';
INSERT INTO iab_validation (testNum, result1, result2, result3, result4, result5)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation),
    count(*),
    a.natural_id,
    a.school_year,
    e.administration_condition_code,
    CASE WHEN e.completeness_code = 'Complete'
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM exam e
    JOIN asmt a ON e.asmt_id = a.id
  WHERE a.type_id = 2
  GROUP BY
    a.school_year,
    a.natural_id,
    e.administration_condition_code,
    e.completeness_code
  ORDER BY count(*), a.natural_id;

-- Exam breakdown by district and school
INSERT INTO iab_validation (testNum, result1, result2, result3, result4)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation) + 1,
    'iab exams',
    'school id',
    'district',
    'school';
INSERT INTO iab_validation (testNum, result1, result2, result3, result4)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation),
    ex.count,
    sch.natural_id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           s.natural_id
         FROM exam e
           JOIN asmt a ON a.id = e.asmt_id
           JOIN school s ON s.id = e.school_id
         WHERE a.type_id = 2
         GROUP BY s.natural_id
       ) ex
    JOIN school sch ON sch.natural_id = ex.natural_id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.natural_id;

-- Exam accommodations
INSERT INTO iab_validation (testNum, result1, result2)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation) + 1,
    'iab accommodations count',
    'ethnicity';
INSERT INTO iab_validation (testNum, result1, result2)
  SELECT
    (SELECT max(testNum)
     FROM iab_validation),
    count(*),
    code
  FROM exam e
    JOIN exam_available_accommodation ea ON e.id = ea.exam_id
    JOIN accommodation a ON a.id = ea.accommodation_id
  WHERE e.type_id = 2
  GROUP BY ea.accommodation_id
  ORDER BY count(*);

# -- Student
# INSERT INTO iab_validation (testNum, result1)
#   SELECT
#     (SELECT max(testNum)
#      FROM iab_validation) + 1,
#     'total students';
# INSERT INTO iab_validation (testNum, result1)
#   SELECT
#     (SELECT max(testNum)
#      FROM iab_validation),
#     count(*)
#   FROM student;
#
# -- Student Ethnicity
# INSERT INTO iab_validation (testNum, result1, result2)
#   SELECT
#     (SELECT max(testNum)
#      FROM iab_validation) + 1,
#     'ethnicity count',
#     'ethnicity';
# INSERT INTO iab_validation (testNum, result1, result2)
#   SELECT
#     (SELECT max(testNum)
#      FROM iab_validation),
#     count(*),
#     ethnicity_code
#   FROM student_ethnicity
#   GROUP BY ethnicity_code
#   ORDER BY count(*);
