USE ${schemaName};

-- add updated timestamp to keep track of the updates; this is meant to help with finding the import id that updated the records
ALTER TABLE accommodation ADD COLUMN updated TIMESTAMP(6) DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(6);

-- remove language table and its dependencies; intead all available languages are loaded
ALTER TABLE accommodation_translation ADD COLUMN language_code varchar(3);
UPDATE accommodation_translation acct
    JOIN language l ON l.id = acct.language_id
SET acct.language_code = l.code;

ALTER TABLE accommodation_translation
    -- add updated timestamp to keep track of the updates; this is meant to help with finding the import id that updated the records
    ADD COLUMN updated TIMESTAMP(6) DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(6),
    DROP FOREIGN KEY fk__accommodation_translation__language,
    DROP INDEX idx__accommodation_translation__language,
    DROP INDEX idx__accommodation_translation__accommodation_language,
    DROP COLUMN language_id,
    MODIFY COLUMN language_code varchar(3) NOT NULL,
    ADD INDEX idx__accommodation_translation__language_code (language_code),
    ADD PRIMARY KEY (accommodation_id, language_code);

DROP TABLE language;
