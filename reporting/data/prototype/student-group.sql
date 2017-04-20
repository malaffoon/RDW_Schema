USE reporting;

-- Below are sample of simplified queries, they need to be further developed during API/UI development

-- Assumptions:
-- 1. Data Mart has only active groups. Migrate will have to take care of it
-- 2. Groups that have no students with the exams will still be in the data mart.
-- 3. Only students with the exams will be in the data mart student_group_membership table.

-- TODOs:
--   decide how to handle 'ids to names' translation. Probably better to do it in Java
--   decide how to populate the filters on the screen? In java?
--   indexes

-- https://confluence.fairwaytech.com/display/SWF/0.1+My+Groups+Widget

SELECT
  g.id
  , g.name
  , g.school_id
  , sch.name
  , g.subject_id
  -- TODO: this is a pretty nasty query. It needs to be worked on or the UI needs to be modified
--   , CASE (SELECT 1
--         FROM dual
--         WHERE exists(
--             SELECT gm.student_id
--             FROM student_group_membership gm
--               JOIN iab_exam iab ON iab.student_id = gm.student_id
--               JOIN school sch ON sch.id = iab.school_id
--             WHERE (sch.id IN (-1) OR sch.district_id IN (-1) OR 1 = 1) AND gm.student_group_id = g.id
--         ))
--   WHEN 1
--     THEN 1
--   ELSE 0
--   END AS has_iabs
--
--   , CASE (SELECT 1
--         FROM dual
--         WHERE exists(
--             SELECT gm.student_id
--             FROM student_group_membership gm
--               JOIN exam e ON e.student_id = gm.student_id
--               JOIN school sch ON sch.id = e.school_id
--             WHERE (sch.id IN (-1) OR sch.district_id IN (-1) OR 1 = 1) AND gm.student_group_id = g.id
--         ))
--   WHEN 1
--     THEN 1
--   ELSE 0
--   END AS has_exams
FROM student_group g
  JOIN school sch ON sch.id = g.school_id
  JOIN user_student_group ug ON ug.student_group_id = g.id
WHERE ug.user_login = 'user8';


-- https://confluence.fairwaytech.com/display/SWF/1.0+Student+Group+Test+Results
-- IAB tab:
explain
SELECT st.*, iab.*, asmt.*
FROM student_group_membership gm
  JOIN iab_exam iab ON iab.student_id = gm.student_id
  JOIN student st on st.id = iab.student_id
  JOIN school sch ON sch.id = iab.school_id
  JOIN asmt asmt on asmt.id = iab.asmt_id
WHERE (sch.id IN (-1) OR sch.district_id IN (-1) OR 1 = 1) AND gm.student_group_id = 2
       and iab.school_year = 2016 and asmt.subject_id = 1

-- ICA tab:
explain
SELECT st.*, exam.*, asmt.*
FROM student_group_membership gm
  JOIN exam exam ON exam.student_id = gm.student_id
  JOIN student st on st.id = exam.student_id
  JOIN school sch ON sch.id = exam.school_id
  JOIN asmt asmt on asmt.id = exam.asmt_id
WHERE (sch.id IN (-1) OR sch.district_id IN (-1) OR 1 = 1) AND gm.student_group_id = 2
      and exam.school_year = 2016 and asmt.subject_id = 1


-- https://confluence.fairwaytech.com/display/SWF/1.0.1+Aggregate+Tabs
-- TODO
--   joins seems to interfere with the indexes; check performance to see if more de-normalization could help with getting it to pick up an index (assuming one is created)
SELECT
  min(completed_at) as date,
  session_id,
  count(*),
  asmt_id,
  avg(scale_score) avg_scale_score,
  sum(is_category1) as is_category1,
  sum(is_category2) as is_category2,
  sum(is_category3) as is_category3,
  sqrt(sum(scale_score_std_err*iab.scale_score_std_err))/count(*) as avg_scale_score_std_err
FROM iab_exam iab
  JOIN student_group_membership gm ON iab.student_id = gm.student_id and gm.student_group_id = 55
  JOIN school sch ON sch.id = iab.school_id
  JOIN asmt a ON a.id = iab.asmt_id
  -- this is probably not needed
  JOIN subject s ON s.id = a.subject_id
WHERE
  (sch.id IN (-1) OR sch.district_id IN (-1) OR 1 = 1)
  AND iab.school_year = 2016
  AND asmt_id in(2)
  -- this is probably not needed
  AND s.id = 1;