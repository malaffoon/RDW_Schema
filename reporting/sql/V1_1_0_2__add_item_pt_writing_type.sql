USE ${schemaName};

ALTER TABLE staging_item ADD COLUMN performance_task_writing_type varchar(16);
ALTER TABLE item ADD COLUMN performance_task_writing_type varchar(16);
