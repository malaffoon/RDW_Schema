-- Modify user_report table to track chunk completion and remove unused job_execution_id column
USE ${schemaName};

ALTER TABLE user_report DROP COLUMN job_execution_id;
ALTER TABLE user_report ADD COLUMN total_chunk_count INT NOT NULL DEFAULT 0;
ALTER TABLE user_report ADD COLUMN complete_chunk_count INT NOT NULL DEFAULT 0;
