/**
*  DWR-449 Performance improvement.
**/

USE ${schemaName};

-- With this index we can do INSERT IGNORE to remove duplicates
CREATE UNIQUE INDEX uk__staging_student_ethnicity ON staging_student_ethnicity (ethnicity_id, student_id);
CREATE UNIQUE INDEX uk__staging_student_group_membership ON staging_student_group_membership (student_group_id, student_id);
CREATE UNIQUE INDEX uk__staging_user_student_group ON staging_user_student_group (student_group_id, user_login);
CREATE UNIQUE INDEX uk__staging_item_other_target ON staging_item_other_target (item_id, target_id);
CREATE UNIQUE INDEX uk__staging_item_common_core_standard ON staging_item_common_core_standard (item_id, common_core_standard_id);
