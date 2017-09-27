-- Merge the staging_exam_student table into the staging_exam table

USE ${schemaName};

ALTER TABLE staging_exam
  ADD COLUMN grade_id tinyint NOT NULL,
  ADD COLUMN student_id int NOT NULL,
  ADD COLUMN school_id int NOT NULL,
  ADD COLUMN iep tinyint NOT NULL,
  ADD COLUMN lep tinyint NOT NULL,
  ADD COLUMN section504 tinyint,
  ADD COLUMN economic_disadvantage tinyint NOT NULL,
  ADD COLUMN migrant_status tinyint,
  ADD COLUMN eng_prof_lvl varchar(20),
  ADD COLUMN t3_program_type varchar(20),
  ADD COLUMN language_code varchar(3),
  ADD COLUMN prim_disability_type varchar(3),
  DROP COLUMN exam_student_id;

DROP TABLE IF EXISTS staging_exam_student;