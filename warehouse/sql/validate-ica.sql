USE warehouse;

CREATE TABLE IF NOT EXISTS ica_validation
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
DELETE FROM ica_validation;

-- Total counts
INSERT INTO ica_validation (testNum, result1)
  SELECT
    1,
    'total_ica';
INSERT INTO ica_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation),
    count(*)
  FROM exam
  WHERE type_id = 1;

INSERT INTO ica_validation (testNum, result1, result2, result3)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation) + 1,
    'total ica score',
    'total std err',
    'total perf level';
INSERT INTO ica_validation (testNum, result1, result2, result3)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation),
    sum(scale_score),
    sum(scale_score_std_err),
    sum(performance_level)
  FROM exam
  WHERE type_id = 1;

-- Exam break down by asmt year, admin condition and complete
INSERT INTO ica_validation (testNum, result1, result2, result3, result4, result5)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation) + 1,
    'ica exams',
    'asmt',
    'asmt year',
    'admin condition',
    'complete';
INSERT INTO ica_validation (testNum, result1, result2, result3, result4, result5)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation),
    count(*),
    a.natural_id,
    a.school_year,
    ac.code,
    CASE WHEN e.completeness_id = 2
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM exam e
    JOIN asmt a ON e.asmt_id = a.id
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  WHERE a.type_id = 1
  GROUP BY
    a.natural_id,
    a.school_year,
    e.administration_condition_id,
    e.completeness_id
  ORDER BY count(*), a.natural_id;

-- Exam breakdown by district and school
INSERT INTO ica_validation (testNum, result1, result2, result3, result4)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation) + 1,
    'ica exams',
    'school id',
    'district',
    'school';
INSERT INTO ica_validation (testNum, result1, result2, result3, result4)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation),
    ex.count,
    sch.natural_id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           s.natural_id
         FROM exam e
           JOIN school s ON s.id = e.school_id
         WHERE e.type_id = 1
         GROUP BY s.natural_id
       ) ex
    JOIN school sch ON sch.natural_id = ex.natural_id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.natural_id;

-- Exam accommodations
INSERT INTO ica_validation (testNum, result1, result2)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation) + 1,
    'ica accommodations count',
    'ethnicity';
INSERT INTO ica_validation (testNum, result1, result2)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation),
    count(*),
    code
  FROM exam e
    JOIN exam_available_accommodation ea ON e.id = ea.exam_id
    JOIN accommodation a ON a.id = ea.accommodation_id
  WHERE e.type_id = 1
  GROUP BY ea.accommodation_id
  ORDER BY count(*);

-- Students
# INSERT INTO post_validation (testNum, result1)
#   SELECT
#     (SELECT max(testNum)
#      FROM post_validation) + 1,
#     'total students';
# INSERT INTO post_validation (testNum, result1)
#   SELECT
#     (SELECT max(testNum)
#      FROM post_validation),
#     count(*)
#   FROM student;

-- Student Ethnicity
# INSERT INTO post_validation (testNum, result1, result2)
#   SELECT
#     (SELECT max(testNum)
#      FROM post_validation) + 1,
#     'ethnicity count',
#     'ethnicity';
# INSERT INTO post_validation (testNum, result1, result2)
#   SELECT
#     (SELECT max(testNum)
#      FROM post_validation),
#     count(*),
#     e.code
#   FROM student_ethnicity se
#     JOIN ethnicity e ON se.ethnicity_id = e.id
#   GROUP BY ethnicity_id
#   ORDER BY count(*);
