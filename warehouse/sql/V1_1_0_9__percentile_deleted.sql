-- Add deleted column to percentile

USE ${schemaName};

ALTER TABLE percentile
  ADD COLUMN deleted TINYINT NOT NULL DEFAULT 0 AFTER max_score;