-- Add exam school year table

USE ${schemaName};

CREATE TABLE IF NOT EXISTS school_year (
  year smallint NOT NULL PRIMARY KEY
);

-- This should not be part of the initial db load, instead it should be treated as 'CODES' and migrated.
-- But since we have the data loaded, in order to define constraints, this is loaded.
INSERT INTO school_year (year) VALUES
  (2015),
  (2016),
  (2017),
  (2018);

ALTER TABLE exam ADD CONSTRAINT fk__exam__school_year FOREIGN KEY (school_year) REFERENCES school_year(year);
ALTER TABLE asmt ADD CONSTRAINT fk__asmt__school_year FOREIGN KEY (school_year) REFERENCES school_year(year);
ALTER TABLE student_group ADD CONSTRAINT fk__student_group__school_year FOREIGN KEY (school_year) REFERENCES school_year(year);

CREATE TABLE IF NOT EXISTS staging_school_year (
  year smallint NOT NULL PRIMARY KEY
);
