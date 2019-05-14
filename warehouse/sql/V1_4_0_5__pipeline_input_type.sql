-- Adds input type column to pipeline table
-- Sets pipeline input types
-- Adds default empty script for each pipeline

use ${schemaName};

ALTER TABLE pipeline
  ADD COLUMN input_type varchar(20);

-- set pipline input types

UPDATE pipeline
  SET input_type = 'xml'
WHERE code in ('exam');

UPDATE pipeline
  SET input_type = 'csv'
WHERE code in ('group', 'assessment');

-- provide pipelines with an empty script

INSERT INTO pipeline_script (pipelineId, body, updated_by) VALUES
 ((SELECT id FROM pipeline WHERE code = 'exam'), '', 'System'),
 ((SELECT id FROM pipeline WHERE code = 'group'), '', 'System'),
 ((SELECT id FROM pipeline WHERE code = 'assessment'), '', 'System');