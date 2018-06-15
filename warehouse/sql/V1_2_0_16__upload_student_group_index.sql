use ${schemaName};

ALTER TABLE upload_student_group
    ADD INDEX idx__upload_student_group__group_import(group_id, import_id);