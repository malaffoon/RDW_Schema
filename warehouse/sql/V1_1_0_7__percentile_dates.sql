-- Add support for percentile start and end date.
-- add min and max score to percentile for optionally supplied min and max of the assessment.
-- change percent to percentile_rank as a more appropriate name.
-- modify the min and max score of the rank to float.

USE ${schemaName};

ALTER TABLE percentile
  ADD COLUMN start_date DATE NOT NULL AFTER asmt_id,
  ADD COLUMN end_date DATE NOT NULL AFTER start_date,
  ADD COLUMN min_score FLOAT AFTER standard_deviation,
  ADD COLUMN max_score FLOAT AFTER min_score,
  ADD UNIQUE INDEX idx__percentile__asmt_start_date_end_date (asmt_id, start_date, end_date);

ALTER TABLE percentile_score
  CHANGE COLUMN percent percentile_rank TINYINT NOT NULL,
  MODIFY COLUMN min_score FLOAT NOT NULL,
  MODIFY COLUMN max_score FLOAT NOT NULL;