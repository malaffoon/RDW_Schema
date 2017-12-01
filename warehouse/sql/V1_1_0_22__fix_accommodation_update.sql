USE ${schemaName};

UPDATE accommodation 
 SET updated = now()
WHERE updated is null;

ALTER TABLE accommodation MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);

UPDATE accommodation_translation 
 SET updated = now()
WHERE updated is null;

ALTER TABLE accommodation_translation MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
