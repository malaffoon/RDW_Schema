-- migrate related changes : adding created column to master entities

USE ${schemaName};

-- -------- asmt changes ------------------------------------------------------------------------------------------------
ALTER TABLE asmt ADD COLUMN created TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6);
UPDATE asmt a
  JOIN import i ON i.id = a.import_id
SET a.created = i.created;

ALTER TABLE asmt DROP INDEX idx__asmt__updated;
ALTER TABLE asmt ADD INDEX idx__asmt__created_updated (created, updated);

-- -------- school changes ------------------------------------------------------------------------------------------------
ALTER TABLE school ADD COLUMN created TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6);
UPDATE school s
  JOIN import i ON i.id = s.import_id
SET s.created = i.created;

ALTER TABLE school DROP INDEX idx__school__updated;
ALTER TABLE school ADD INDEX idx__school__created_updated (created, updated);

-- -------- student changes ------------------------------------------------------------------------------------------------
ALTER TABLE student ADD COLUMN created TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6);
UPDATE student s
  JOIN import i ON i.id = s.import_id
SET s.created = i.created;

ALTER TABLE student DROP INDEX idx__student__updated;
ALTER TABLE student ADD INDEX idx__student__created_uodated (created, updated);

-- -------- student_group changes ------------------------------------------------------------------------------------------------
ALTER TABLE student_group DROP INDEX idx__student_group__updated;
ALTER TABLE student_group ADD INDEX idx__student_group__created_updated (created, updated);

-- -------- exam changes ------------------------------------------------------------------------------------------------
ALTER TABLE exam ADD COLUMN created TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6);
UPDATE exam s
  JOIN import i ON i.id = s.import_id
SET s.created = i.created;

ALTER TABLE exam DROP INDEX idx__exam__updated;
ALTER TABLE exam ADD INDEX idx__exam__created_updated (created, updated);