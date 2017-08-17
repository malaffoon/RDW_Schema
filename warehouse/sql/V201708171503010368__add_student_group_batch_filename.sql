-- Modify upload_student_group_batch to include uploaded file name

USE ${schemaName};

ALTER TABLE upload_student_group_batch ADD filename VARCHAR(200);
