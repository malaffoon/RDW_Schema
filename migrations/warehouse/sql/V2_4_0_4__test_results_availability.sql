-- v2.4.0_4 flyway script
--
-- adds support for finer-grained embargo control
--
use ${schemaName};

ALTER TABLE district_embargo
    ADD COLUMN subject_id smallint,
    ADD CONSTRAINT fk__district_embargo__subject FOREIGN KEY (subject_id) REFERENCES subject(id),
    ADD INDEX idx__district_embargo__subject (subject_id),
    DROP PRIMARY KEY,
    ADD PRIMARY KEY(school_year, district_id, subject_id);

CREATE TABLE embargo_report_type (
    name VARCHAR(20) PRIMARY KEY
);

INSERT INTO embargo_report_type VALUES ('Aggregate'), ('Individual');
