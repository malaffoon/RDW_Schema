-- Update the unique index to consider the school id
-- Modify the upload student_id column to match the student.id type

USE ${schemaName};

ALTER TABLE upload_student_group_import
  DROP INDEX idx__upload_student_group_import__batch_ref;

ALTER TABLE upload_student_group_import
  ADD UNIQUE INDEX idx__upload_student_group_import__batch_ref_school (batch_id, ref_type, school_id);

ALTER TABLE upload_student_group
  MODIFY COLUMN student_id int(11);