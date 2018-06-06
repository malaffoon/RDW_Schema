-- Should I add a reference to this or somewhere else?
-- https://github.com/SmarterApp/RDW/blob/develop/docs/Monitoring.md
--
-- Warning : This is a CPU intensive report that may take minutes to run. It is strongly advisable to run
-- this report during the maintenance window, and while the system is inactive and the exam processors
-- are paused.
SELECT
  e.school_year                                         AS test_administration_year,
  e.asmt_id                                             AS assessment_db_id,
  a.natural_id                                          AS asessment_natural_id,
  count(*)                                              AS total_results,
  count(s.last_or_surname) / count(*) * 100             AS percent_of_results_with_student_last_or_surname,
  count(s.birthday) / count(*) * 100                    AS percent_of_results_with_student_birthday,
  count(s.gender_id) / count(*) * 100                   AS percent_of_results_with_student_gender,
  count(se.ethnicity_id) / count(*) * 100               AS percent_of_results_with_student_race,
  count(e.grade_id) / count(*) * 100                    AS percent_of_results_with_enrolled_grade,
  count(e.iep) / count(*) * 100                         AS percent_of_results_with_iep,
  count(e.lep) / count(*) * 100                         AS percent_of_results_with_lep,
  count(e.section504) / count(*) * 100                  AS percent_of_results_with_section504,
  count(e.economic_disadvantage) / count(*) * 100       AS percent_of_results_with_economic_disadvantage,
  count(e.migrant_status) / count(*) * 100              AS percent_of_results_with_migrant_status,
  count(e.administration_condition_id) / count(*) * 100 AS percent_of_results_with_administration_condition,
  -- is this `validity`?
  count(e.completeness_id) / count(*) * 100             AS percent_of_results_with_completeness,
  count(e.session_id) / count(*) * 100                  AS percent_of_results_with_session_id
FROM exam e
  JOIN student s ON s.id = e.student_id
  JOIN asmt a ON a.id = e.asmt_id
  JOIN (SELECT s.id, max(se.ethnicity_id) AS ethnicity_id
          FROM student s LEFT JOIN student_ethnicity se ON s.id = se.student_id
          GROUP BY s.id
       ) se ON se.id = e.student_id
-- optionally include : WHERE e.deleted = 0
GROUP BY e.asmt_id, e.school_year;