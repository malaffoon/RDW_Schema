USE reporting;

-- Assumptions:
-- 1. Data Mart has only active groups. Migrate will have to take care of it
-- 2. Groups that have no students with the exams will still be in the data mart.
-- 3. Only students with the exams will be in the data mart student_group_membership table.

-- https://confluence.fairwaytech.com/display/SWF/0.1+My+Groups+Widget

RESET QUERY CACHE;
explain
SELECT
  g.id
  , g.name
  , g.school_id
  , sch.name
  , g.subject_id
  -- TODO: this is a pretty nasty query. It needs to be worked on or the UI needs to be modified
#   , CASE (SELECT 1
#         FROM dual
#         WHERE exists(
#             SELECT gm.student_id
#             FROM student_group_membership gm
#               JOIN iab_exam iab ON iab.student_id = gm.student_id
#               JOIN school sch ON sch.id = iab.school_id
#             WHERE (sch.id IN (-1) OR district_id IN (-1) OR 1 = 1) AND gm.student_group_id = g.id
#         ))
#   WHEN 1
#     THEN 1
#   ELSE 0
#   END AS has_iabs
#
#   , CASE (SELECT 1
#         FROM dual
#         WHERE exists(
#             SELECT gm.student_id
#             FROM student_group_membership gm
#               JOIN exam e ON e.student_id = gm.student_id
#               JOIN school sch ON sch.id = e.school_id
#             WHERE (sch.id IN (-1) OR district_id IN (-1) OR 1 = 1) AND gm.student_group_id = g.id
#         ))
#   WHEN 1
#     THEN 1
#   ELSE 0
#   END AS has_exams

# FROM user_student_group ug
#   JOIN student_group g ON ug.student_group_id = g.id
#   JOIN school sch ON sch.id = g.school_id
# WHERE ug.user_login = 'user8';

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
WHERE (sch.id IN (-1) OR district_id IN (-1) OR 1 = 1) AND gm.student_group_id = 2
       and iab.school_year = 2016 and asmt.subject_id = 1

-- ICA tab:
explain
SELECT st.*, exam.*, asmt.*
FROM student_group_membership gm
  JOIN exam exam ON exam.student_id = gm.student_id
  JOIN student st on st.id = exam.student_id
  JOIN school sch ON sch.id = exam.school_id
  JOIN asmt asmt on asmt.id = exam.asmt_id
WHERE (sch.id IN (-1) OR district_id IN (-1) OR 1 = 1) AND gm.student_group_id = 2
      and exam.school_year = 2016 and asmt.subject_id = 1