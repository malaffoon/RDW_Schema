-- Add support for percentile start and end date.
-- add min and max score to percentile for optionally supplied min and max of the assessment.
-- change percent to percentile_rank as a more appropriate name.
-- modify the min and max score of the rank to float.

USE ${schemaName};

ALTER TABLE percentile
  ADD COLUMN start_date DATE NOT NULL AFTER asmt_id,
  ADD COLUMN end_date DATE NOT NULL AFTER start_date,
  ADD COLUMN min_score FLOAT NOT NULL AFTER standard_deviation,
  ADD COLUMN max_score FLOAT NOT NULL AFTER min_score,
  ADD UNIQUE INDEX idx__percentile__asmt_start_date_end_date (asmt_id, start_date, end_date);

ALTER TABLE percentile_score
  CHANGE COLUMN percent percentile_rank TINYINT NOT NULL,
  ADD COLUMN score float NOT NULL AFTER percentile_rank,
  CHANGE COLUMN min_score min_inclusive FLOAT NOT NULL,
  CHANGE COLUMN max_score max_exclusive FLOAT NOT NULL;

ALTER TABLE staging_percentile
  ADD COLUMN start_date DATE NOT NULL AFTER asmt_id,
  ADD COLUMN end_date DATE NOT NULL AFTER start_date,
  ADD COLUMN min_score FLOAT NOT NULL AFTER standard_deviation,
  ADD COLUMN max_score FLOAT NOT NULL AFTER min_score,
  ADD UNIQUE INDEX idx__staging_percentile__asmt_start_date_end_date (asmt_id, start_date, end_date);

ALTER TABLE staging_percentile_score
  CHANGE COLUMN percent percentile_rank TINYINT NOT NULL,
  ADD COLUMN score float NOT NULL AFTER percentile_rank,
  CHANGE COLUMN min_score min_inclusive FLOAT NOT NULL,
  CHANGE COLUMN max_score max_exclusive FLOAT NOT NULL;