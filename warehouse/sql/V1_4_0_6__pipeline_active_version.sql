-- Adds active version column to pipeline table
-- Makes pipeline input_type column not null

use ${schemaName};

ALTER TABLE pipeline
  ADD COLUMN active_version int;

ALTER TABLE pipeline
  MODIFY input_type varchar(20) NOT NULL;
