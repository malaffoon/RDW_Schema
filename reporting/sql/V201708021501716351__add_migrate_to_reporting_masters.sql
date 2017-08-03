# add migrate_id to reporting masters entities

USE ${schemaName};

ALTER TABLE asmt ADD COLUMN migrate_id bigint;
UPDATE asmt SET migrate_id = -1;
ALTER TABLE asmt MODIFY COLUMN migrate_id bigint NOT NULL;

ALTER TABLE exam ADD COLUMN migrate_id bigint;
UPDATE exam SET migrate_id = -1;
ALTER TABLE exam MODIFY COLUMN migrate_id bigint NOT NULL;

ALTER TABLE school ADD COLUMN migrate_id bigint;
UPDATE school SET migrate_id = -1;
ALTER TABLE school MODIFY COLUMN migrate_id bigint NOT NULL;

ALTER TABLE student  ADD COLUMN migrate_id bigint;
UPDATE student SET migrate_id = -1;
ALTER TABLE student MODIFY COLUMN migrate_id bigint NOT NULL;

ALTER TABLE student_group ADD COLUMN migrate_id bigint;
UPDATE student_group SET migrate_id = -1;
ALTER TABLE student_group MODIFY COLUMN migrate_id bigint NOT NULL;

