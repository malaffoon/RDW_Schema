-- migrate related changes : adding new columns

USE ${schemaName};

ALTER TABLE migrate ADD COLUMN first_at TIMESTAMP(6);
ALTER TABLE migrate ADD COLUMN last_at TIMESTAMP(6);

ALTER TABLE asmt ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE school ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE student ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE student_group ADD COLUMN updated TIMESTAMP(6);
ALTER TABLE exam ADD COLUMN updated TIMESTAMP(6);