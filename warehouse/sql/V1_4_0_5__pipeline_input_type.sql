-- Adds input type column to pipeline table and sets each pipelines input types

use ${schemaName};

ALTER TABLE pipeline
  ADD COLUMN input_type varchar(20);

UPDATE pipeline
  SET input_type = 'xml'
WHERE code in ('exam');

UPDATE pipeline
  SET input_type = 'csv'
WHERE code in ('group', 'assessment');
