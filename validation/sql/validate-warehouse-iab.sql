USE warehouse;

CREATE TABLE IF NOT EXISTS post_validation
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
DELETE FROM post_validation;

-- Total counts
INSERT INTO post_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM post_validation) + 1,
    'total_iab';
INSERT INTO post_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM post_validation),
    count(*)
  FROM exam
  WHERE type_id = 2
    AND deleted = 0;

INSERT INTO post_validation (testNum, result1, result2, result3)
  SELECT
    (SELECT max(testNum)
     FROM post_validation) + 1,
    'total iab score',
    'total std err',
    'total perf level';
INSERT INTO post_validation (testNum, result1, result2, result3)
  SELECT
    (SELECT max(testNum)
     FROM post_validation),
    sum(scale_score),
    sum(scale_score_std_err),
    sum(performance_level)
  FROM exam
  WHERE type_id = 2
    AND deleted = 0;

-- Exam break down by asmt year, admin condition and complete
INSERT INTO post_validation (testNum, result1, result2, result3, result4, result5)
  SELECT
    (SELECT max(testNum)
     FROM post_validation) + 1,
    'iab exams',
    'asmt',
    'asmt year',
    'admin condition',
    'complete';
INSERT INTO post_validation (testNum, result1, result2, result3, result4, result5)
  SELECT
    (SELECT max(testNum)
     FROM post_validation),
    count(*),
    a.id,
    a.school_year,
    ac.code,
    CASE WHEN e.completeness_id = 2
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM exam e
    JOIN asmt a ON e.asmt_id = a.id
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  WHERE a.type_id = 2
    AND a.deleted = 0
    AND e.deleted = 0
  GROUP BY
    a.school_year,
    a.id,
    e.administration_condition_id,
    e.completeness_id
  ORDER BY count(*), a.id;

-- Exam breakdown by district and school
INSERT INTO post_validation (testNum, result1, result2, result3, result4)
  SELECT
    (SELECT max(testNum)
     FROM post_validation) + 1,
    'iab exams',
    'school id',
    'district',
    'school';
INSERT INTO post_validation (testNum, result1, result2, result3, result4)
  SELECT
    (SELECT max(testNum)
     FROM post_validation),
    ex.count,
    sch.id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           s.id
         FROM exam e
           JOIN school s ON s.id = e.school_id
         WHERE e.type_id = 2
           AND e.deleted = 0
         GROUP BY s.id
       ) ex
    JOIN school sch ON sch.id = ex.id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.id;

-- Exam accommodations
-- INSERT INTO post_validation (testNum, result1, result2)
--   SELECT
--     (SELECT max(testNum)
--      FROM post_validation) + 1,
--     'iab accommodations count',
--     'ethnicity';
-- INSERT INTO post_validation (testNum, result1, result2)
--   SELECT
--     (SELECT max(testNum)
--      FROM post_validation),
--     count(*),
--     code
--   FROM exam e
--     JOIN exam_available_accommodation ea ON e.id = ea.exam_id
--     JOIN accommodation a ON a.id = ea.accommodation_id
--   WHERE e.type_id = 2
--     AND e.deleted = 0
--   GROUP BY ea.accommodation_id
--   ORDER BY count(*);

#-- Students
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
#
#-- Student Ethnicity
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
