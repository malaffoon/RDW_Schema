-- add school_year table

SET SEARCH_PATH to ${schemaName};

CREATE TABLE school_year (
  year smallint PRIMARY KEY SORTKEY
) DISTSTYLE ALL;

CREATE TABLE staging_school_year (
  year smallint PRIMARY KEY SORTKEY,
  migrate_id bigint NOT NULL
);

-- in the real life this should be managed via migrate, remove it when consolidating the scripts
INSERT INTO school_year (year) VALUES
  (2015),
  (2016),
  (2017),
  (2018);

-- Add type_id and rename the table.
-- Since type_id must be NOT NULL, it needs to be added, populated and then NOT NULL is updated
-- Redshift does not support changing columns; instead a new table needs to be created and the data is copied
CREATE TABLE asmt (
  id bigint encode raw  PRIMARY KEY SORTKEY,
  grade_id smallint NOT NULL,
  school_year smallint NOT NULL,
  subject_id smallint NOT NULL,
  type_id smallint NOT NULL,
  name character varying(250) NOT NULL,
  migrate_id bigint encode delta NOT NULL,
  update_import_id bigint encode delta NOT NULL,
  CONSTRAINT fk__asmt__type FOREIGN KEY(type_id) REFERENCES asmt(id),
  CONSTRAINT fk__asmt__subject FOREIGN KEY(subject_id) REFERENCES subject(id),
  CONSTRAINT fk__asmt__grade FOREIGN KEY(grade_id) REFERENCES grade(id),
  CONSTRAINT fk__asmt__school_year FOREIGN KEY(school_year) REFERENCES school_year(year)
) DISTSTYLE ALL;

-- force type_id to be 1 since this is all what we have loaded so far
INSERT INTO asmt (id, grade_id, school_year, subject_id, type_id, name, migrate_id, update_import_id)
 SELECT id, grade_id, school_year, subject_id, 1 as type_id, name, migrate_id, update_import_id from  ica_asmt;

-- this is not use for now
DROP TABLE fact_student_ica_exam_for_longitudinal;

-- remove 'ica' from table and FK
ALTER TABLE fact_student_ica_exam RENAME TO fact_student_exam;

ALTER TABLE fact_student_exam DROP CONSTRAINT fk__fact_student_ica_exam__ica_asmt;
ALTER TABLE fact_student_exam DROP CONSTRAINT fk__fact_student_ica_exam__school;
ALTER TABLE fact_student_exam DROP CONSTRAINT fk__fact_student_ica_exam__student;

ALTER TABLE fact_student_exam ADD CONSTRAINT fk__fact_student_exam__school_year FOREIGN KEY(school_year) REFERENCES school_year(year);
ALTER TABLE fact_student_exam ADD CONSTRAINT fk__fact_student_exam__asmt FOREIGN KEY(asmt_id) REFERENCES asmt(id);
ALTER TABLE fact_student_exam ADD CONSTRAINT fk__fact_student_exam__school FOREIGN KEY(school_id) REFERENCES school(id);
ALTER TABLE fact_student_exam ADD CONSTRAINT fk__fact_student_exam__student FOREIGN KEY(student_id) REFERENCES student(id);

DROP TABLE ica_asmt;