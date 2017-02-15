/**
** Remove is_demo flag from the student table; the rdw is not supposed to receive demo records.
** Remove exam location.
** Make an exam's session not optional.
**/
USE warehouse;

CREATE TABLE application_schema_version (
   major_version int UNIQUE NOT NULL
);

INSERT INTO application_schema_version (major_version) VALUES (0);

ALTER TABLE student DROP COLUMN is_demo;

ALTER TABLE iab_exam
  DROP FOREIGN KEY fk__iab_exam__exam_location,
  DROP COLUMN asmt_session_location_id,
  MODIFY session_id varchar(128) NOT NULL;

ALTER TABLE exam
  DROP FOREIGN KEY fk__exam__exam_location,
  DROP COLUMN asmt_session_location_id,
  MODIFY session_id varchar(128) NOT NULL;

DROP TABLE asmt_session_location;

