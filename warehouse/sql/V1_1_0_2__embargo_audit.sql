/*
  Embargo audit tables and triggers. Note that embargo auditing is not driven by the system configuration.
*/
USE ${schemaName};

CREATE TABLE IF NOT EXISTS audit_district_embargo (
  id            BIGINT                                    NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action        VARCHAR(8)                                NOT NULL,
  audited       TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255)                              NOT NULL,
  district_id   INT                                       NOT NULL,
  school_year   SMALLINT                                  NOT NULL,
  individual    TINYINT,
  aggregate     TINYINT,
  updated       TIMESTAMP(6)                              NOT NULL,
  updated_by    VARCHAR(255)
);

CREATE TRIGGER trg__district_embargo__insert
AFTER INSERT ON district_embargo
FOR EACH ROW
  INSERT INTO audit_district_embargo (action, database_user, district_id, school_year, individual, aggregate, updated, updated_by)
    SELECT
      'insert',
      USER(),
      NEW.district_id,
      NEW.school_year,
      NEW.individual,
      NEW.aggregate,
      NEW.updated,
      NEW.updated_by;

CREATE TRIGGER trg__district_embargo__update
AFTER UPDATE ON district_embargo
FOR EACH ROW
  INSERT INTO audit_district_embargo (action, database_user, district_id, school_year, individual, aggregate, updated, updated_by)
    SELECT
      'update',
      USER(),
      NEW.district_id,
      NEW.school_year,
      NEW.individual,
      NEW.aggregate,
      NEW.updated,
      NEW.updated_by;

CREATE TRIGGER trg__district_embargo__delete
AFTER DELETE ON district_embargo
FOR EACH ROW
  INSERT INTO audit_district_embargo (action, database_user, district_id, school_year, individual, aggregate, updated, updated_by)
    SELECT
      'delete',
      USER(),
      OLD.district_id,
      OLD.school_year,
      OLD.individual,
      OLD.aggregate,
      OLD.updated,
      OLD.updated_by;

CREATE TABLE IF NOT EXISTS audit_state_embargo (
  id            BIGINT                                    NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action        VARCHAR(8)                                NOT NULL,
  audited       TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255)                              NOT NULL,
  school_year   SMALLINT                                  NOT NULL,
  individual    TINYINT,
  aggregate     TINYINT,
  updated       TIMESTAMP(6)                              NOT NULL,
  updated_by    VARCHAR(255)
);

CREATE TRIGGER trg__state_embargo__insert
AFTER INSERT ON state_embargo
FOR EACH ROW
  INSERT INTO audit_state_embargo (action, database_user, school_year, individual, aggregate, updated, updated_by)
    SELECT
      'insert',
      USER(),
      NEW.school_year,
      NEW.individual,
      NEW.aggregate,
      NEW.updated,
      NEW.updated_by;

CREATE TRIGGER trg__state_embargo__update
AFTER UPDATE ON state_embargo
FOR EACH ROW
  INSERT INTO audit_state_embargo (action, database_user, school_year, individual, aggregate, updated, updated_by)
    SELECT
      'update',
      USER(),
      NEW.school_year,
      NEW.individual,
      NEW.aggregate,
      NEW.updated,
      NEW.updated_by;

CREATE TRIGGER trg__state_embargo__delete
AFTER DELETE ON state_embargo
FOR EACH ROW
  INSERT INTO audit_state_embargo (action, database_user, school_year, individual, aggregate, updated, updated_by)
    SELECT
      'delete',
      USER(),
      OLD.school_year,
      OLD.individual,
      OLD.aggregate,
      OLD.updated,
      OLD.updated_by;