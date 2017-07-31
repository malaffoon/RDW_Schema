-- migrate related changes : restore updated to the right value, it was corrupted by the previous migrate

USE ${schemaName};

UPDATE asmt a
  JOIN import i ON i.id = a.update_import_id
SET a.updated = i.updated;

UPDATE school s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

UPDATE student s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

UPDATE student_group s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;

UPDATE exam s
  JOIN import i ON i.id = s.update_import_id
SET s.updated = i.updated;
