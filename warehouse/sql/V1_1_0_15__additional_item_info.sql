USE ${schemaName};

ALTER TABLE item
    ADD COLUMN options_count tinyint,
    ADD COLUMN answer_key varchar(50);
