-- add index to support code migration

USE ${schemaName};

ALTER TABLE import ADD INDEX idx__import__content_status_created(content, status, created);