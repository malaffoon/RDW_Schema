USE ${schemaName};

ALTER TABLE user_report
  ADD COLUMN updated TIMESTAMP(6),
  DROP COLUMN job_execution_id;

UPDATE user_report
 SET updated = created;

ALTER TABLE user_report
  MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
