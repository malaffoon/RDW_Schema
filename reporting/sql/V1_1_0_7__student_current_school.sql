-- add student current school/district and exam ids from which it was derived
USE ${schemaName};

ALTER TABLE student
    ADD COLUMN inferred_school_id int,
    ADD INDEX idx__student__inferred_school (inferred_school_id),
    ADD CONSTRAINT fk__student__inferred_school_id FOREIGN KEY (inferred_school_id) REFERENCES school(id);

ALTER TABLE staging_student
    ADD COLUMN inferred_school_id int;
