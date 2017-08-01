-- more migrate related changes

USE ${schemaName};

ALTER TABLE migrate ADD INDEX idx__migrate__status_last_at (status, last_at);

ALTER TABLE migrate ADD COLUMN size SMALLINT;
ALTER TABLE migrate ADD COLUMN migrate_codes TINYINT;