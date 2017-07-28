-- migrate related changes : adding index to import

USE ${schemaName};

ALTER TABLE import ADD INDEX idx__import__updated_status (updated, status);