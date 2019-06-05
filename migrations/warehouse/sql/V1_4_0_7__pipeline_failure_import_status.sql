-- Adds active version column to pipeline table
-- Makes pipeline input_type column not null

use ${schemaName};

INSERT INTO import_status (id, name) VALUES
(-7, 'PIPELINE_FAILURE');
