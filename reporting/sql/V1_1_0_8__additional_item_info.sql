USE ${schemaName};

ALTER TABLE item
    ADD COLUMN field_test tinyint,
    ADD COLUMN active tinyint,
    ADD COLUMN type varchar(40),
    ADD COLUMN number_of_answer_options tinyint,
    ADD COLUMN answer_key varchar(50);

ALTER TABLE staging_item
    ADD COLUMN field_test tinyint,
    ADD COLUMN active tinyint,
    ADD COLUMN type varchar(40),
    ADD COLUMN number_of_answer_options tinyint,
    ADD COLUMN answer_key varchar(50);
