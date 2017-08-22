-- Update the unique index to consider the school id

USE ${schemaName};

ALTER TABLE upload_student_group_import
  DROP INDEX idx__upload_student_group_import__batch_ref;

ALTER TABLE upload_student_group_import
  ADD UNIQUE INDEX idx__upload_student_group_import__batch_ref_school (batch_id, ref_type, school_id);
