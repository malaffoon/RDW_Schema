-- migrate related changes : clean up

USE ${schemaName};

ALTER TABLE staging_asmt MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;
ALTER TABLE staging_school MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;
ALTER TABLE staging_student MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;
ALTER TABLE staging_student_group MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;
ALTER TABLE staging_exam MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;
