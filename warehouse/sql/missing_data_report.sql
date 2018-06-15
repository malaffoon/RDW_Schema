-- -----------------------------------------------------------------------------------------------------------
-- Warning : These are CPU intensive reports that may take minutes to run. It is strongly advisable to run
-- them report during the maintenance window, and while the system is inactive and the exam processors are paused.
-- -----------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------
-- Summary diagnostic reports by test administration year and assessments
-- -----------------------------------------------------------------------------------------------------------

--  A summary diagnostic report indicating which the missing key data elements.
--  To speed up its run time, this report does not include students' race or exam item data.
SELECT
  e.school_year                                         AS test_administration_year,
  e.asmt_id                                             AS assessment_db_id,
  a.natural_id                                          AS asessment_natural_id,
  count(*)                                              AS total_results,
  count(s.last_or_surname) / count(*) * 100             AS percent_of_results_with_student_last_or_surname,
  count(s.birthday) / count(*) * 100                    AS percent_of_results_with_student_birthday,
  count(s.gender_id) / count(*) * 100                   AS percent_of_results_with_student_gender,
  count(e.grade_id) / count(*) * 100                    AS percent_of_results_with_enrolled_grade,
  count(e.iep) / count(*) * 100                         AS percent_of_results_with_iep,
  count(e.lep) / count(*) * 100                         AS percent_of_results_with_lep,
  count(e.section504) / count(*) * 100                  AS percent_of_results_with_section504,
  count(e.economic_disadvantage) / count(*) * 100       AS percent_of_results_with_economic_disadvantage,
  count(e.migrant_status) / count(*) * 100              AS percent_of_results_with_migrant_status,
  count(e.administration_condition_id) / count(*) * 100 AS percent_of_results_with_administration_condition,
  count(e.completeness_id) / count(*) * 100             AS percent_of_results_with_completeness,
  count(e.session_id) / count(*) * 100                  AS percent_of_results_with_session_id
FROM exam e
  JOIN student s ON s.id = e.student_id
  JOIN asmt a ON a.id = e.asmt_id
-- optionally include : WHERE e.deleted = 0
GROUP BY e.asmt_id, e.school_year;

--  A summary diagnostic report indicating missing students' race data.
SELECT
  e.school_year                                         AS test_administration_year,
  e.asmt_id                                             AS assessment_db_id,
  a.natural_id                                          AS asessment_natural_id,
  count(*)                                              AS total_results,
  count(se.ethnicity_id) / count(*) * 100               AS percent_of_results_with_student_race
FROM exam e
  JOIN asmt a ON a.id = e.asmt_id
  JOIN (SELECT s.id, max(se.ethnicity_id) AS ethnicity_id FROM student s LEFT JOIN student_ethnicity se ON s.id = se.student_id GROUP BY s.id) se ON se.id = e.student_id
-- optionally include : WHERE e.deleted = 0
GROUP BY e.asmt_id, e.school_year;

--  A summary diagnostic report indicating missing exams' items
-- NOTE: due to a large volume of the exam's items this query may take a while to complete
SELECT
	e.school_year                                         AS test_administration_year,
	e.asmt_id                                             AS assessment_db_id,
	a.natural_id                                          AS asessment_natural_id,
	count(*)                                              AS total_results,
	count(ei.item_id) / count(*) * 100              	  AS percent_of_results_with_items
FROM exam e
	JOIN asmt a ON a.id = e.asmt_id
	JOIN (SELECT e.id as exam_id, max(ei.id) AS item_id FROM exam e LEFT JOIN exam_item ei ON e.id = ei.exam_id GROUP BY e.id) ei ON ei.exam_id = e.id
-- optionally include : WHERE e.deleted = 0
GROUP BY e.asmt_id, e.school_year

-- -----------------------------------------------------------------------------------------------------------
-- Summary diagnostic reports with breakdown by school and an optional filter by district
-- -----------------------------------------------------------------------------------------------------------

--  A summary diagnostic report indicating which the missing key data elements.
--  To speed up its run time, this report does not include students' race or exam item data.
SELECT
  e.school_year                                         AS test_administration_year,
  e.asmt_id                                             AS assessment_db_id,
  a.natural_id                                          AS asessment_natural_id,
  e.school_id                                           AS schol_db_id,
  sch.natural_id                                        AS school_natural_id,
  sch.name                                              AS school_name,
  d.natural_id                                          AS distict_natural_id,
  d.name                                                AS district_name,
  count(*)                                              AS total_results,
  count(s.last_or_surname) / count(*) * 100             AS percent_of_results_with_student_last_or_surname,
  count(s.birthday) / count(*) * 100                    AS percent_of_results_with_student_birthday,
  count(s.gender_id) / count(*) * 100                   AS percent_of_results_with_student_gender,
  count(e.grade_id) / count(*) * 100                    AS percent_of_results_with_enrolled_grade,
  count(e.iep) / count(*) * 100                         AS percent_of_results_with_iep,
  count(e.lep) / count(*) * 100                         AS percent_of_results_with_lep,
  count(e.section504) / count(*) * 100                  AS percent_of_results_with_section504,
  count(e.economic_disadvantage) / count(*) * 100       AS percent_of_results_with_economic_disadvantage,
  count(e.migrant_status) / count(*) * 100              AS percent_of_results_with_migrant_status,
  count(e.administration_condition_id) / count(*) * 100 AS percent_of_results_with_administration_condition,
  count(e.completeness_id) / count(*) * 100             AS percent_of_results_with_completeness,
  count(e.session_id) / count(*) * 100                  AS percent_of_results_with_session_id
FROM exam e
  JOIN student s ON s.id = e.student_id
  JOIN asmt a ON a.id = e.asmt_id
  JOIN school sch ON sch.id = e.school_id
  JOIN district d ON d.id = sch.district_id
-- optionally include : WHERE d.natural_id = 'put district id here'
-- optionally include : AND e.deleted = 0
GROUP BY e.asmt_id, e.school_year, e.school_id;

--  A summary diagnostic report indicating missing students' race data.
SELECT
  e.school_year                           AS test_administration_year,
  e.asmt_id                               AS assessment_db_id,
  a.natural_id                            AS asessment_natural_id,
  e.school_id                             AS schol_db_id,
  sch.natural_id                          AS school_natural_id,
  sch.name                                AS school_name,
  d.natural_id                            AS distict_natural_id,
  d.name                                  AS district_name,
  count(*)                                AS total_results,
  count(se.ethnicity_id) / count(*) * 100 AS percent_of_results_with_student_race
FROM exam e
  JOIN asmt a ON a.id = e.asmt_id
  JOIN (SELECT s.id, max(se.ethnicity_id) AS ethnicity_id FROM student s LEFT JOIN student_ethnicity se ON s.id = se.student_id GROUP BY s.id) se ON se.id = e.student_id
  JOIN school sch ON sch.id = e.school_id
  JOIN district d ON d.id = sch.district_id
-- optionally include : WHERE d.natural_id = 'put district id here'
-- optionally include : AND e.deleted = 0
GROUP BY e.asmt_id, e.school_year, e.school_id;

--  A summary diagnostic report indicating missing exams' items
-- NOTE: due to a large volume of the exam's items this query may take a while to complete
SELECT
	e.school_year                           AS test_administration_year,
	e.asmt_id                               AS assessment_db_id,
	a.natural_id                            AS asessment_natural_id,
	e.school_id                             AS schol_db_id,
	sch.natural_id                          AS school_natural_id,
	sch.name                                AS school_name,
	d.natural_id                            AS distict_natural_id,
	d.name                                  AS district_name,
	count(*)                                AS total_results,
	count(ei.item_id) / count(*) * 100      AS percent_of_results_with_items
FROM exam e
	JOIN asmt a ON a.id = e.asmt_id
	JOIN (SELECT e.id as exam_id, max(ei.id) AS item_id FROM exam e LEFT JOIN exam_item ei ON e.id = ei.exam_id GROUP BY e.id) ei ON ei.exam_id = e.id
	JOIN school sch ON sch.id = e.school_id
	JOIN district d ON d.id = sch.district_id
-- optionally include : WHERE d.natural_id = 'put district id here'
-- optionally include : AND e.deleted = 0
GROUP BY e.asmt_id, e.school_year, e.school_id;