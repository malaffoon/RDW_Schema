-- migrate related changes : adding created column to master entities

USE ${schemaName};

ALTER TABLE asmt DROP INDEX idx__asmt__created_updated;
ALTER TABLE asmt ADD INDEX idx__asmt__created (created);
ALTER TABLE asmt ADD INDEX idx__asmt__updated (updated);

ALTER TABLE school DROP INDEX idx__school__created_updated;
ALTER TABLE school ADD INDEX idx__school__created (created);
ALTER TABLE school ADD INDEX idx__school__updated (updated);

ALTER TABLE student DROP INDEX idx__student__created_uodated;
ALTER TABLE student ADD INDEX idx__student__created (created);
ALTER TABLE student ADD INDEX idx__student__updated (updated);

ALTER TABLE student_group DROP INDEX idx__student_group__created_updated;
ALTER TABLE student_group ADD INDEX idx__student_group__created (created);
ALTER TABLE student_group ADD INDEX idx__student_group__updated(updated);

ALTER TABLE exam DROP INDEX idx__exam__created_updated;
ALTER TABLE exam ADD INDEX idx__exam__created (created);
ALTER TABLE exam ADD INDEX idx__exam__updated (updated);