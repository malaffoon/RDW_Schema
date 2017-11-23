-- Add audit tables and triggers for student groups

USE ${schemaName};

-- Add timestamp to student group child tables to support auditing
-- Existing records need to have this value set in development, QA, staging and production.
ALTER TABLE student_group_membership
  ADD COLUMN created timestamp(6) default CURRENT_TIMESTAMP(6) not null;

ALTER TABLE user_student_group
  ADD COLUMN created timestamp(6) default CURRENT_TIMESTAMP(6) not null;

CREATE TABLE audit_student_group (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  student_group_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  school_id INT NOT NULL,
  school_year SMALLINT(6) NOT NULL,
  subject_id TINYINT NULL,
  active TINYINT NOT NULL,
  creator VARCHAR(250) NULL,
  import_id BIGINT NOT NULL,
  update_import_id BIGINT NOT NULL,
  deleted TINYINT NOT NULL,
  created TIMESTAMP(6) NOT NULL,
  updated TIMESTAMP(6) NOT NULL
);

CREATE TRIGGER trg__student_group__update
BEFORE UPDATE ON student_group
FOR EACH ROW
  INSERT INTO audit_student_group (
    action, database_user, student_group_id, name, school_id, school_year, subject_id, active, creator, import_id, update_import_id, deleted, created, updated
  )
    SELECT
      'update',
      USER(),
      OLD.id,
      OLD.name,
      OLD.school_id,
      OLD.school_year,
      OLD.subject_id,
      OLD.active,
      OLD.creator,
      OLD.import_id,
      OLD.update_import_id,
      OLD.deleted,
      OLD.created,
      OLD.updated
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

CREATE TRIGGER trg__student_group__delete
BEFORE DELETE ON student_group
FOR EACH ROW
  INSERT INTO audit_student_group (
    action, database_user, student_group_id, name, school_id, school_year, subject_id, active, creator, import_id, update_import_id, deleted, created, updated
  )
    SELECT
      'delete',
      USER(),
      OLD.id,
      OLD.name,
      OLD.school_id,
      OLD.school_year,
      OLD.subject_id,
      OLD.active,
      OLD.creator,
      OLD.import_id,
      OLD.update_import_id,
      OLD.deleted,
      OLD.created,
      OLD.updated
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

CREATE TABLE audit_student_group_membership (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  student_group_id INT NOT NULL,
  student_id INT NOT NULL,
  created TIMESTAMP(6) NOT NULL
);

CREATE TRIGGER trg__student_group_membership__update
BEFORE UPDATE ON student_group_membership
FOR EACH ROW
  INSERT INTO audit_student_group_membership (
    action, database_user, student_group_id, student_id, created
  )
    SELECT
      'update',
      USER(),
      OLD.student_group_id,
      OLD.student_id,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';


CREATE TRIGGER trg__student_group_membership__delete
BEFORE DELETE ON student_group_membership
FOR EACH ROW
  INSERT INTO audit_student_group_membership (
    action, database_user, student_group_id, student_id, created
  )
    SELECT
      'delete',
      USER(),
      OLD.student_group_id,
      OLD.student_id,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

CREATE TABLE audit_user_student_group (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  student_group_id INT NOT NULL,
  user_login VARCHAR(255) NOT NULL,
  created TIMESTAMP(6) NOT NULL
);

CREATE TRIGGER trg__user_student_group__update
BEFORE UPDATE ON user_student_group
FOR EACH ROW
  INSERT INTO audit_user_student_group (
    action, database_user, student_group_id, user_login, created
  )
    SELECT
      'update',
      USER(),
      OLD.student_group_id,
      OLD.user_login,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

CREATE TRIGGER trg__user_student_group__delete
BEFORE DELETE ON user_student_group
FOR EACH ROW
  INSERT INTO audit_user_student_group (
    action, database_user, student_group_id, user_login, created
  )
    SELECT
      'delete',
      USER(),
      OLD.student_group_id,
      OLD.user_login,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';