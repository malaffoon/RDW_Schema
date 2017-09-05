-- add index to support monitoring queries

USE ${schemaName};

ALTER TABLE import ADD INDEX idx__import__status_updated (status, updated);