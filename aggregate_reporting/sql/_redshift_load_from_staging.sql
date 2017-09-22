INSERT INTO subject (id, code)
  SELECT
    id,
    code
  FROM staging_subject;

INSERT INTO grade (id, code, name)
  SELECT
    id,
    code,
    name
  FROM staging_grade;

INSERT INTO asmt_type (id, code, name)
  SELECT
    id,
    code,
    name
  FROM staging_asmt_type;

INSERT INTO completeness (id, code)
  SELECT
    id,
    code
  FROM staging_completeness;

INSERT INTO administration_condition (id, code)
  SELECT
    id,
    code
  FROM staging_administration_condition;

INSERT INTO district (id, natural_id, name)
  SELECT
    id,
    natural_id,
    name
  FROM staging_district;

INSERT INTO school (id, natural_id, name, district_id)
  SELECT
    id,
    natural_id,
    name,
    district_id
  FROM staging_school;

INSERT INTO ica_asmt (id, grade_id, school_year, subject_id)
  SELECT
    id,
    grade_id,
    school_year,
    subject_id
  FROM staging_asmt
  WHERE type_id = 1;

INSERT INTO iab_asmt (id, grade_id, school_year, subject_id)
  SELECT
    id,
    grade_id,
    school_year,
    subject_id
  FROM staging_asmt
  WHERE type_id = 2;


INSERT INTO gender (id, code)
  SELECT
    id,
    code
  FROM staging_gender;

INSERT INTO ethnicity (id, code)
  SELECT
    id,
    code
  FROM staging_ethnicity;

-- TODO: this does not seem right, needs more attention later
INSERT INTO student (id, gender_id)
  SELECT
    id,
    gender_id
  FROM staging_student;

INSERT INTO student_ethnicity (ethnicity_id, student_id)
  SELECT
    ethnicity_id,
    student_id
  FROM staging_student_ethnicity;

-- facts

INSERT INTO fact_student_ica_exam (
  id,
  school_id,
  student_id,
  asmt_id,
  grade_id,
  asmt_grade_id,
  school_year,
  iep,
  lep,
  section504,
  economic_disadvantage,
  migrant_status,
  completeness_id,
  administration_condition_id,
  scale_score,
  scale_score_std_err,
  performance_level,
  claim1_scale_score,
  claim1_scale_score_std_err,
  claim1_category,
  claim2_scale_score,
  claim2_scale_score_std_err,
  claim2_category,
  claim3_scale_score,
  claim3_scale_score_std_err,
  claim3_category,
  claim4_scale_score,
  claim4_scale_score_std_err,
  claim4_category
)
  SELECT
    se.id,
    school_id,
    student_id,
    asmt_id,
    ses.grade_id,
    sa.grade_id,
    se.school_year,
    iep,
    lep,
    section504,
    economic_disadvantage,
    migrant_status,
    completeness_id,
    administration_condition_id,
    se.scale_score,
    se.scale_score_std_err,
    se.performance_level,
    claim1.scale_score as claim1_scale_score,
    claim1.scale_score_std_err as claim1_scale_score_std_err,
    claim1.category as claim1_category,
    claim2.scale_score as claim2_scale_score,
    claim2.scale_score_std_err as claim2_scale_score_std_err,
    claim2.category as claim2_category,
    claim3.scale_score as claim3_scale_score,
    claim3.scale_score_std_err as claim3_scale_score_std_err,
    claim3.category as claim3_category,
    claim4.scale_score as claim4_scale_score,
    claim4.scale_score_std_err as claim4_scale_score_std_err,
    claim4.category as claim4_category
  FROM staging_exam se
    JOIN staging_exam_student ses ON se.exam_student_id = ses.id
    JOIN staging_school ssch ON ssch.id = ses.school_id
    JOIN staging_asmt sa ON sa.id = se.asmt_id
    JOIN staging_student ss ON ss.id = ses.student_id
    LEFT JOIN (
                SELECT s.exam_id
                  ,s.scale_score
                  ,s.scale_score_std_err
                  ,s.category
                FROM staging_exam_claim_score s
                  INNER JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.subject_claim_score_id
                                                           AND m.num = 1
              ) AS claim1 ON claim1.exam_id = se.id
    LEFT JOIN (
                SELECT s.exam_id
                  ,s.scale_score
                  ,s.scale_score_std_err
                  ,s.category
                FROM staging_exam_claim_score s
                  INNER JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.subject_claim_score_id
                                                           AND m.num = 2
              ) AS claim2 ON claim2.exam_id = se.id
    LEFT JOIN (
                SELECT s.exam_id
                  ,s.scale_score
                  ,s.scale_score_std_err
                  ,s.category
                FROM staging_exam_claim_score s
                  INNER JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.subject_claim_score_id
                                                           AND m.num = 3
              ) AS claim3 ON claim3.exam_id = se.id
    LEFT JOIN (
                SELECT s.exam_id
                  ,s.scale_score
                  ,s.scale_score_std_err
                  ,s.category
                FROM staging_exam_claim_score s
                  INNER JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.subject_claim_score_id
                                                           AND m.num = 4
              ) AS claim4 ON claim4.exam_id = se.id
  WHERE sa.type_id = 1;
-- 1217410 rows affected in 12s 182ms


INSERT INTO fact_student_iab_exam (
  id,
  school_id,
  student_id,
  asmt_id,
  asmt_grade_id,
  grade_id,
  school_year,
  iep,
  lep,
  section504,
  economic_disadvantage,
  migrant_status,
  completeness_id,
  administration_condition_id,
  scale_score,
  scale_score_std_err,
  performance_level
)
  SELECT
    se.id,
    school_id,
    student_id,
    asmt_id,
    sa.grade_id,
    ses.grade_id,
    se.school_year,
    iep,
    lep,
    section504,
    economic_disadvantage,
    migrant_status,
    completeness_id,
    administration_condition_id,
    se.scale_score,
    se.scale_score_std_err,
    se.performance_level
  FROM staging_exam se
    JOIN staging_exam_student ses ON se.exam_student_id = ses.id
    JOIN staging_school ssch ON ssch.id = ses.school_id
    JOIN staging_asmt sa ON sa.id = se.asmt_id
    JOIN staging_student ss ON ss.id = ses.student_id
  WHERE sa.type_id = 2;
--  24215377 rows affected in 45s 546ms

VACUUM;
ANALYZE;