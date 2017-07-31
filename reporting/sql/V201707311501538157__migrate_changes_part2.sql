-- migrate related changes : removing unused columns

USE ${schemaName};

-- NOTE: before applying this script all migrates have to be completed
UPDATE migrate SET first_at = CURRENT_TIMESTAMP(6) WHERE first_at IS NULL;
UPDATE migrate SET last_at = CURRENT_TIMESTAMP(6) WHERE last_at IS NULL;

ALTER TABLE migrate MODIFY COLUMN first_at TIMESTAMP(6) NOT NULL;
ALTER TABLE migrate MODIFY COLUMN last_at TIMESTAMP(6) NOT NULL;

ALTER TABLE migrate DROP COLUMN first_import_id;
ALTER TABLE migrate DROP COLUMN last_import_id;

UPDATE asmt SET updated = CURRENT_TIMESTAMP(6) WHERE updated IS NULL;
ALTER TABLE asmt MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;

UPDATE school SET updated = CURRENT_TIMESTAMP(6) WHERE updated IS NULL;
ALTER TABLE school MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;

UPDATE student SET updated = CURRENT_TIMESTAMP(6) WHERE updated IS NULL;
ALTER TABLE student MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;

UPDATE student_group SET updated = CURRENT_TIMESTAMP(6) WHERE updated IS NULL;
ALTER TABLE student_group MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;

UPDATE exam SET updated = CURRENT_TIMESTAMP(6) WHERE updated IS NULL;
ALTER TABLE exam MODIFY COLUMN updated TIMESTAMP(6) NOT NULL;
