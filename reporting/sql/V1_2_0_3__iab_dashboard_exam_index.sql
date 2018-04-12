-- Flyway script to add exam index for the IAB dashboard query
--
USE ${schemaName};

ALTER TABLE exam
  -- new index for the dashboard query
  ADD INDEX idx__exam__student_asmt_type_school_year_completed_at (student_id, asmt_id, type_id, school_year, completed_at),

  -- replace foreign key index with the new one
  DROP FOREIGN KEY fk__exam__student,
  DROP INDEX idx__exam__student;

ALTER TABLE exam ADD CONSTRAINT fk__exam__student FOREIGN KEY (student_id) REFERENCES student(id);
