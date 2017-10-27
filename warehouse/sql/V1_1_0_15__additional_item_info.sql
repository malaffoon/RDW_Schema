USE ${schemaName};

ALTER TABLE item
    ADD COLUMN number_of_answer_options tinyint,
    ADD COLUMN answer_key varchar(50);
