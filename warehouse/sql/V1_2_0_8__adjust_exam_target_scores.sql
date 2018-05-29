-- Clean up indexes and drop unused column
USE ${schemaName};

ALTER TABLE exam_target_score
 -- remove FK that use indexes to be modified
  DROP FOREIGN KEY fk__exam_target_score__target,
  DROP FOREIGN KEY fk__exam_target_score__exam,
  -- drop indexes due to bad names
  DROP INDEX idx__exam_claim_score__exam,
  DROP INDEX idx__exam_target_score_exam_target;

ALTER TABLE exam_target_score
  -- restore indexes and FKs
  ADD UNIQUE KEY idx__exam_target_score__exam_target(exam_id, target_id),
  ADD INDEX idx__exam_target_score__target(target_id),
  ADD CONSTRAINT fk__exam_target_score__exam FOREIGN KEY (exam_id) REFERENCES exam(id),
  ADD CONSTRAINT fk__exam_target_score__target FOREIGN KEY (target_id) REFERENCES target(id),
  -- remove unused column
  DROP COLUMN   performance_level;