-- add completed_at to the index since it is used in the ORDER BY

USE ${schemaName};

ALTER TABLE reporting.exam
  ADD INDEX idx__exam__asmt_school_school_year_completed_at (asmt_id, school_id, school_year, completed_at);

ALTER TABLE reporting.exam
  DROP INDEX idx__exam__asmt_school_year;

