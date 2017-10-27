USE ${schemaName};

ALTER TABLE item
    ADD COLUMN answer_options tinyint,
    ADD COLUMN answer_key varchar(50);
