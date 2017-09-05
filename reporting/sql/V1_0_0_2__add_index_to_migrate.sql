-- add index to support monitoring queries

USE ${schemaName};

ALTER TABLE migrate ADD  INDEX idx__migrate_status_created (status, created);