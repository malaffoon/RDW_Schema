------------------------------------------------------------------------------------------------------------
-- Achievement level report grades 3 and 4, years 2017 and 2018 by schools and withing each school by asmt grade and gender
------------------------------------------------------------------------------------------------------------
SELECT
  count(*)         AS count,
  avg(scale_score) AS score,
  sum(CASE WHEN performance_level = 1 THEN 1 ELSE 0 END)  AS level1,
  sum(CASE WHEN performance_level = 2 THEN 1 ELSE 0 END)  AS level2,
  sum(CASE WHEN performance_level = 3 THEN 1 ELSE 0 END)  AS level3,
  sum(CASE WHEN performance_level = 4 THEN 1 ELSE 0 END)  AS level4,
  fe.asmt_grade_id,
  fe.gender_id,
  fe.school_year,
  a.subject_id,
  sch.name         AS name,
  'school'         AS type,
  'gender'         AS subgroup
FROM fact_student_ica_exam fe
  JOIN school sch ON sch.id = fe.school_id
  JOIN student s ON fe.student_id = s.id
  JOIN ica_asmt a ON a.id = fe.asmt_id
WHERE
  fe.school_year IN (2017, 2018) AND
  fe.asmt_grade_id IN ('4', '5')
GROUP BY fe.asmt_grade_id,
  fe.gender_id,
  fe.school_year,
  a.subject_id,
  sch.name
ORDER BY  a.subject_id, sch.name, fe.school_year,fe.asmt_grade_id,fe.gender_id;


------------------------------------------------------------------------------------------------------------
-- group of students in cohort throughout all selected years
------------------------------------------------------------------------------------------------------------
SELECT
  count(*),
  cast(avg(score) AS INT),
  asmt_grade_id,
  school_year,
  school_id
FROM (
       -- get the highest student score within a school
       SELECT
         fe.student_id,
         max(fe.scale_score) AS score,
         fe.asmt_grade_id,
         fe.school_year,
         a.subject_id,
         fe.school_id,
         count(*) OVER (PARTITION BY student_id, school_id) AS year_in_one_inst
       FROM fact_student_ica_exam fe
         JOIN ica_asmt a ON a.id = fe.asmt_id
       WHERE
         a.subject_id = 1
         AND
         (
           (fe.school_year = 2017 AND fe.asmt_grade_id = '3') OR
           (fe.school_year = 2018 AND fe.asmt_grade_id = '4')
         )
       GROUP BY fe.student_id,
         fe.asmt_grade_id,
         fe.school_year,
         a.subject_id,
         fe.school_id
     ) s
-- this needs to match the number of years included, it removes students that are not found in all the years
WHERE year_in_one_inst = 2
GROUP BY
  asmt_grade_id,
  school_year,
  school_id
ORDER BY school_id
  , school_year
  , asmt_grade_id;