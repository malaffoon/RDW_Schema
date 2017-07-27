-- migrate related changes : adding new columns

USE ${schemaName};

-- -------- asmt changes ------------------------------------------------------------------------------------------------
ALTER TABLE asmt ADD COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
UPDATE asmt a
  JOIN import i ON i.id = a.update_import_id
SET a.updated = i.updated;

ALTER TABLE asmt ADD INDEX idx__asmt__updated (updated);

-- -------- school changes ------------------------------------------------------------------------------------------------
ALTER TABLE school ADD COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
UPDATE school s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

ALTER TABLE school ADD INDEX idx__school__updated (updated);

-- -------- student changes ------------------------------------------------------------------------------------------------
ALTER TABLE student ADD COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
UPDATE student s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

ALTER TABLE student ADD INDEX idx__student__updated (updated);

-- -------- student_group changes ------------------------------------------------------------------------------------------------
ALTER TABLE student_group ADD COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
UPDATE student_group s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

ALTER TABLE student_group ADD INDEX idx__student_group__updated (updated);

-- -------- exam changes ------------------------------------------------------------------------------------------------
ALTER TABLE exam ADD COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
UPDATE exam s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

ALTER TABLE exam ADD INDEX idx__exam__updated (updated);