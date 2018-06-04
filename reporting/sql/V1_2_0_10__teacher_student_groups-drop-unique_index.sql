use ${schemaName};

ALTER TABLE teacher_student_group
  DROP INDEX idx__teacher_student_group__user_login,
  -- removes unique index
  DROP INDEX idx__teacher_student_group__user_login_name_school_year,
  -- re-create index without UNIQUE constraint
  ADD INDEX idx__teacher_student_group__user_login_name_school_year (user_login, name, school_year);