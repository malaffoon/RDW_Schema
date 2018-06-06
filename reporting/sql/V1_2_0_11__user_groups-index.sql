use ${schemaName};

ALTER TABLE user_student_group
 DROP FOREIGN KEY fk__user_student_group__student_group,
 DROP INDEX idx__user_student_group;

ALTER TABLE user_student_group
  -- reverse the order of columns in the index
  ADD UNIQUE KEY idx__user_student_group(user_login, student_group_id),
  -- add index to support FK
  ADD INDEX idx__user_student_group__student_group(student_group_id),
  ADD CONSTRAINT fk__user_student_group__student_group FOREIGN KEY (student_group_id) REFERENCES student_group(id);
