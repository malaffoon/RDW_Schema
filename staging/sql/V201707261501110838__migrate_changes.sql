-- migrate related changes : adding new columns

USE ${schemaName};

-- -------- asmt changes ------------------------------------------------------------------------------------------------
ALTER TABLE staging_asmt ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE staging_school ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE staging_student ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE staging_student_group ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE staging_exam ADD COLUMN updated TIMESTAMP(6);
