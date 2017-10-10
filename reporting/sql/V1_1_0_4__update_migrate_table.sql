-- Modify migrate table to be in synch with the migrate_olap schema

USE ${schemaName};

ALTER TABLE migrate MODIFY COLUMN size int;