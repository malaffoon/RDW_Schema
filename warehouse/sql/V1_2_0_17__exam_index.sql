-- add indexes to support migrate
use ${schemaName};

ALTER TABLE exam
 ADD INDEX idx__exam__type_deleted_created_and_scores (type_id, deleted, created, scale_score, scale_score_std_err, performance_level);

ALTER TABLE exam
 ADD INDEX idx__exam__type_deleted_updated_and_scores (type_id, deleted, updated, scale_score, scale_score_std_err, performance_level);
