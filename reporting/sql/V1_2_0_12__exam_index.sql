use ${schemaName};

-- TODO: this index was manually created on awsdev with name 'test' and needs to be dropped
ALTER TABLE exam ADD INDEX idx__exam__student_school_completed_at (student_id, school_id, completed_at);