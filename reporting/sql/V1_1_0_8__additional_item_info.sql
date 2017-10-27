USE ${schemaName};

ALTER TABLE item
    ADD COLUMN field_test tinyint,
    ADD COLUMN active tinyint,
    ADD COLUMN type varchar(40),
    ADD COLUMN answer_options tinyint,
    ADD COLUMN answer text;

ALTER TABLE staging_item
    ADD COLUMN field_test tinyint,
    ADD COLUMN active tinyint,
    ADD COLUMN type varchar(40),
    ADD COLUMN answer_options tinyint,
    ADD COLUMN answer text;
