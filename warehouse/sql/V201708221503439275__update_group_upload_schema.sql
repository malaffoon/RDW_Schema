-- Modify upload_student_group "group_name" column to match csv headers

USE ${schemaName};

ALTER TABLE upload_student_group
  CHANGE name group_name VARCHAR(255);
