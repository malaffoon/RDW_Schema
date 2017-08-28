use reporting;

CREATE TABLE IF NOT EXISTS post_validation
(
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  testNum int,
  result1 varchar(1000),
  result2 varchar(1000),
  result3 varchar(1000),
  result4 varchar(1000),
  result5 varchar(1000),
  result6 varchar(1000),
  result7 varchar(1000),
  result8 varchar(1000),
  created timestamp default current_timestamp
);

--  Total counts
INSERT INTO post_validation(testNum, result1) SELECT 1, 'total_ica';
INSERT INTO post_validation(testNum, result1)
  SELECT (SELECT max(testNum) FROM post_validation),
   count(*) FROM exam WHERE type_id = 1;

INSERT INTO post_validation(testNum, result1) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'total_iab';
INSERT INTO post_validation(testNum, result1)
  SELECT (SELECT max(testNum) FROM post_validation),
    count(*) FROM exam WHERE type_id = 2;

INSERT INTO post_validation(testNum, result1, result2, result3)  SELECT (SELECT max(testNum) FROM post_validation) + 1, 'total ica score', 'total std err', 'total perf level';
INSERT INTO post_validation(testNum, result1, result2, result3)
  SELECT (SELECT max(testNum) FROM post_validation),
  sum(scale_score), sum(scale_score_std_err), sum(performance_level) FROM exam WHERE type_id = 1;

INSERT INTO post_validation(testNum, result1, result2, result3) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'total iab score', 'total std err', 'total perf level';
INSERT INTO post_validation(testNum, result1, result2, result3)
  SELECT (SELECT max(testNum) FROM post_validation),
  sum(scale_score), sum(scale_score_std_err), sum(performance_level) FROM exam WHERE type_id = 2;

INSERT INTO post_validation(testNum, result1)  SELECT (SELECT max(testNum) FROM post_validation) + 1, 'total students';
INSERT INTO post_validation(testNum, result1)
  SELECT (SELECT max(testNum) FROM post_validation),
    count(*) FROM student;

-- Exam break down by asmt year, admin condition and complete
INSERT INTO post_validation(testNum, result1, result2, result3, result4, result5) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'ica exams', 'asmt', 'asmt year', 'admin condition', 'complete';
INSERT INTO post_validation(testNum, result1, result2, result3, result4, result5)
  SELECT (SELECT max(testNum) FROM post_validation),
   count(*),
   a.natural_id,
   e.school_year,
   administration_condition_code,
   completeness_code
 FROM exam e JOIN asmt a ON e.asmt_id = a.id
   WHERE a.type_id = 1
GROUP BY  a.natural_id,
   a.school_year,
   administration_condition_code,
   completeness_code
ORDER BY count(*), a.natural_id;

INSERT INTO post_validation(testNum, result1, result2, result3, result4, result5) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'iab exams', 'asmt', 'asmt year', 'admin condition', 'complete';
INSERT INTO post_validation(testNum, result1, result2, result3, result4, result5)
  SELECT (SELECT max(testNum) FROM post_validation),
   count(*),
   a.natural_id,
   e.school_year,
   administration_condition_code,
   CASE WHEN completeness_code = 'Complete' THEN 'TRUE' ELSE 'FALSE' END
 FROM exam e JOIN asmt a ON e.asmt_id = a.id
   WHERE a.type_id = 2
GROUP BY  a.school_year, a.natural_id, administration_condition_code, completeness_code
ORDER BY count(*), a.natural_id;

--   Exam breakdown by district and school
INSERT INTO post_validation(testNum, result1, result2, result3, result4) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'ica exams', 'school id', 'district', 'school';
INSERT INTO post_validation(testNum, result1, result2, result3, result4)
  SELECT (SELECT max(testNum) FROM post_validation),
   s.count,
   sch.natural_id,
   UPPER(d.name),
   UPPER(sch.name)
 FROM (
        SELECT
          count(*) as count,
          s.natural_id
        FROM exam e
          JOIN asmt a ON a.id = e.asmt_id
          JOIN school s ON s.id = e.school_id
        WHERE a.type_id = 1
        GROUP BY natural_id
      ) s JOIN school sch ON sch.natural_id = s.natural_id JOIN district d ON d.id = sch.district_id
 ORDER BY  natural_id, s.count;

INSERT INTO post_validation(testNum, result1, result2, result3, result4) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'iab exams', 'school id', 'district', 'school';
INSERT INTO post_validation(testNum, result1, result2, result3, result4)
  SELECT (SELECT max(testNum) FROM post_validation),
   s.count,
   sch.natural_id,
   UPPER(d.name),
   UPPER(sch.name)
 FROM (
        SELECT
          count(*) as count,
          s.natural_id
        FROM exam e
          JOIN asmt a ON a.id = e.asmt_id
          JOIN school s ON s.id = e.school_id
        WHERE a.type_id = 2
        GROUP BY natural_id
      ) s JOIN school sch ON sch.natural_id = s.natural_id JOIN district d ON d.id = sch.district_id
 ORDER BY natural_id, s.count;

-- Student
INSERT INTO post_validation(testNum, result1, result2) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'ethnicity count', 'ethnicity';
INSERT INTO post_validation(testNum, result1, result2)
  SELECT (SELECT max(testNum) FROM post_validation),
    count(*), ethnicity_code  FROM student_ethnicityGROUP BY ethnicity_codeORDER BY count(*);

-- Exam accommodations
INSERT INTO post_validation(testNum, result1, result2) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'ica accommodations count', 'ethnicity';
INSERT INTO post_validation(testNum, result1, result2)
SELECT (SELECT max(testNum) FROM post_validation),
 count(*), code FROM exam e JOIN exam_available_accommodation ea ON e.id = ea.exam_id JOIN accommodation a ON a.id = ea.accommodation_id WHERE e.type_id = 1GROUP BY ea.accommodation_idORDER BY count(*);

INSERT INTO post_validation(testNum, result1, result2) SELECT (SELECT max(testNum) FROM post_validation) + 1, 'iab accommodations count', 'ethnicity';
INSERT INTO post_validation(testNum, result1, result2)
SELECT (SELECT max(testNum) FROM post_validation),
    count(*), code FROM exam e JOIN exam_available_accommodation ea ON e.id = ea.exam_id JOIN accommodation a ON a.id = ea.accommodation_id WHERE e.type_id = 2GROUP BY ea.accommodation_idORDER BY count(*);