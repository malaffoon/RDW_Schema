-- differences:
-- no iabs
-- no asmt.natural_id (should we import these for the script?)
-- no school.natural_id
-- no accommodations

SET SEARCH_PATH TO reporting_olap;

CREATE TABLE IF NOT EXISTS ica_validation
(
  id      BIGINT IDENTITY (1, 1),
  testNum INT,
  result1 VARCHAR(1000),
  result2 VARCHAR(1000),
  result3 VARCHAR(1000),
  result4 VARCHAR(1000),
  result5 VARCHAR(1000),
  result6 VARCHAR(1000),
  result7 VARCHAR(1000),
  result8 VARCHAR(1000),
  created TIMESTAMP DEFAULT current_timestamp
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
  FROM fact_student_ica_exam;

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
     FROM post_validation),
    sum(scale_score),
    sum(scale_score_std_err),
    sum(performance_level)
  FROM fact_student_ica_exam;

INSERT INTO ica_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM post_validation) + 1,
    'total students';
INSERT INTO ica_validation (testNum, result1)
  SELECT
    (SELECT max(testNum)
     FROM post_validation),
    count(*)
  FROM student;

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
    a.id,
    a.school_year, -- was incorrectly? e.school_year
    ac.code,
    CASE WHEN completeness_id = 2
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM fact_student_ica_exam e
    JOIN ica_asmt a ON e.asmt_id = a.id
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  GROUP BY
    a.id,
    a.school_year, -- mismatching with select
    ac.code,
    completeness_id
  ORDER BY count(*), a.id;

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
    s.count,
    sch.id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           s.id
         FROM fact_student_ica_exam e
           JOIN ica_asmt a ON a.id = e.asmt_id
           JOIN school s ON s.id = e.school_id
         GROUP BY s.id -- s.id was ambiguous natural_id
       ) s
    JOIN school sch ON sch.id = s.id
    JOIN district d ON d.id = sch.district_id
  ORDER BY s.id, s.count; -- s.id was ambiguous natural_id

-- Student Ethnicity
INSERT INTO ica_validation (testNum, result1, result2)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation) + 1,
    'ethnicity count',
    'ethnicity';
INSERT INTO ica_validation (testNum, result1, result2)
  SELECT
    (SELECT max(testNum)
     FROM ica_validation),
    count(*),
    e.code
  FROM student_ethnicity se
    JOIN ethnicity e ON se.ethnicity_id = e.id
  GROUP BY e.code
  ORDER BY count(*);
