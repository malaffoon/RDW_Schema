-- Flyway script to add exam index for the IAB dashboard query
--
USE ${schemaName};

ALTER TABLE exam
-- new index for the dashboard query
  ADD INDEX idx__exam__student_type_school_year_scores (student_id, school_year, type_id, scale_score, scale_score_std_err, performance_level),
  -- replace foreign key index with the new one
  DROP FOREIGN KEY fk__exam__student,
  DROP INDEX idx__exam__student;

ALTER TABLE exam ADD CONSTRAINT fk__exam__student FOREIGN KEY (student_id) REFERENCES student(id);
