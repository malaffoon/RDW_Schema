/** update import id to root tables **/

USE ${schemaName};

ALTER TABLE asmt ADD update_import_id bigint,
    ADD CONSTRAINT fk__asmt__upd_import_id FOREIGN KEY (update_import_id) REFERENCES import(id);
UPDATE asmt SET update_import_id = import_id;
ALTER TABLE asmt MODIFY update_import_id bigint NOT NULL;
-- TODO: revisit this index
ALTER TABLE asmt ADD INDEX idx__asmt_imports_deleted (import_id, update_import_id, deleted);

ALTER TABLE school ADD update_import_id bigint,
    ADD CONSTRAINT fk__school__upd_import_id FOREIGN KEY (update_import_id) REFERENCES import(id);
UPDATE school SET update_import_id = import_id;
ALTER TABLE school MODIFY update_import_id bigint NOT NULL;
-- TODO: revisit this index
ALTER TABLE school ADD INDEX idx__asmt_imports_deleted (import_id, update_import_id, deleted);

ALTER TABLE student ADD update_import_id bigint,
    ADD CONSTRAINT fk__student__upd_import_id FOREIGN KEY (update_import_id) REFERENCES import(id);
UPDATE student SET update_import_id = import_id;
ALTER TABLE student MODIFY update_import_id bigint NOT NULL;
-- TODO: revisit this index
ALTER TABLE student ADD INDEX idx__asmt_imports_deleted (import_id, update_import_id, deleted);

ALTER TABLE student_group ADD update_import_id bigint,
    ADD CONSTRAINT fk__student_group__upd_import_id FOREIGN KEY (update_import_id) REFERENCES import(id);
UPDATE student_group SET update_import_id = import_id;
ALTER TABLE student_group MODIFY update_import_id bigint;
-- TODO: revisit this index
ALTER TABLE student_group ADD INDEX idx__asmt_imports_deleted (import_id, update_import_id, deleted, active);

ALTER TABLE iab_exam ADD update_import_id bigint,
    ADD CONSTRAINT fk__iab_exam__upd_import_id FOREIGN KEY (update_import_id) REFERENCES import(id);
UPDATE iab_exam SET update_import_id = import_id;
ALTER TABLE iab_exam MODIFY update_import_id bigint NOT NULL;
-- TODO: revisit this index
ALTER TABLE iab_exam ADD INDEX idx__asmt_imports_deleted (import_id, update_import_id, deleted);

ALTER TABLE exam ADD update_import_id bigint,
    ADD CONSTRAINT fk__exam__upd_import_id FOREIGN KEY (update_import_id) REFERENCES import(id);
UPDATE exam SET update_import_id = import_id;
ALTER TABLE exam MODIFY update_import_id bigint NOT NULL;
-- TODO: revisit this index
ALTER TABLE exam ADD INDEX idx__asmt_imports_deleted (import_id, update_import_id, deleted);

/************************************* Stored procedures ***************************************/

/** Student upsert **/
DROP PROCEDURE IF EXISTS student_upsert;

DELIMITER //
CREATE PROCEDURE student_upsert(IN  p_ssid                          VARCHAR(65),
                                IN  p_last_or_surname               VARCHAR(60),
                                IN  p_first_name                    VARCHAR(60),
                                IN  p_middle_name                   VARCHAR(60),
                                IN  p_gender_id                     TINYINT,
                                IN  p_first_entry_into_us_school_at DATE,
                                IN  p_lep_entry_at                  DATE,
                                IN  p_lep_exit_at                   DATE,
                                IN  p_birthday                      DATE,
                                IN  p_import_id                     BIGINT,
                                OUT p_id                            int)
  BEGIN

    DECLARE isUpdate TINYINT;

    --  handle duplicate entry: if there are two competing inserts, one will end up here
    DECLARE CONTINUE HANDLER FOR 1062
    BEGIN
      SELECT id INTO p_id FROM student WHERE ssid = p_ssid;
    END;

    SELECT id INTO p_id FROM student WHERE ssid = p_ssid;

    IF (p_id IS NOT NULL)
    THEN
      -- check if there is anything to update
      SELECT CASE WHEN count(*) > 0 THEN 0 ELSE 1 END INTO isUpdate FROM student
      WHERE id = p_id
            AND last_or_surname = p_last_or_surname
            AND first_name = p_first_name
            AND middle_name = p_middle_name
            AND gender_id = p_gender_id
            AND first_entry_into_us_school_at <=> p_first_entry_into_us_school_at
            AND lep_entry_at <=> p_lep_entry_at
            AND lep_exit_at <=> p_lep_exit_at
            AND birthday = p_birthday;

      IF (isUpdate = 1)
      THEN
        UPDATE student
        SET
          last_or_surname               = p_last_or_surname,
          first_name                    = p_first_name,
          middle_name                   = p_middle_name,
          gender_id                     = p_gender_id,
          first_entry_into_us_school_at = p_first_entry_into_us_school_at,
          lep_entry_at                  = p_lep_entry_at,
          lep_exit_at                   = p_lep_exit_at,
          birthday                      = p_birthday,
          update_import_id                 = p_import_id
        WHERE id = p_id;
      END IF;
    ELSE
      INSERT INTO student (ssid, last_or_surname, first_name, middle_name, gender_id, first_entry_into_us_school_at, lep_entry_at, lep_exit_at, birthday, import_id, update_import_id)
      VALUES (p_ssid, p_last_or_surname, p_first_name, p_middle_name, p_gender_id, p_first_entry_into_us_school_at, p_lep_entry_at, p_lep_exit_at, p_birthday, p_import_id, p_import_id);

      SELECT id INTO p_id FROM student WHERE ssid = p_ssid;
    END IF;
  END; //
DELIMITER ;

/** District upsert **/

DROP PROCEDURE IF EXISTS district_upsert;

DELIMITER //
CREATE PROCEDURE district_upsert(IN  p_name       VARCHAR(100),
                                 IN  p_natural_id VARCHAR(40),
                                 OUT p_id         MEDIUMINT)
  BEGIN

    --  handle duplicate entry: if there are two competing inserts, one will end up here
    DECLARE CONTINUE HANDLER FOR 1062
    BEGIN
      SELECT id INTO p_id FROM district WHERE natural_id = p_natural_id;
    END;

    SELECT id INTO p_id FROM district WHERE natural_id = p_natural_id;

    IF (p_id IS NOT NULL)
    THEN
    -- TODO: this needs to be revisited; afraid it is an overkill to do an update here
      UPDATE district SET name = p_name WHERE id = p_id;
    ELSE
      INSERT INTO district (name, natural_id)
      VALUES (p_name, p_natural_id);

      SELECT id INTO p_id FROM district WHERE natural_id = p_natural_id;
    END IF;
  END; //
DELIMITER ;

/** School upsert **/

DROP PROCEDURE IF EXISTS school_upsert;

DELIMITER //
CREATE PROCEDURE school_upsert(IN  p_district_name       VARCHAR(100),
                               IN  p_district_natural_id VARCHAR(40),
                               IN  p_name                VARCHAR(100),
                               IN  p_natural_id          VARCHAR(40),
                               IN  p_import_id           BIGINT,
                               OUT p_id                  MEDIUMINT)
  BEGIN
    DECLARE p_district_id MEDIUMINT;
    DECLARE isUpdate TINYINT;

    --  handle duplicate entry: if there are two competing inserts, one will end up here
    DECLARE CONTINUE HANDLER FOR 1062
    BEGIN
      SELECT id INTO p_id FROM school WHERE natural_id = p_natural_id;
    END;

    -- there is no transaction since the worse that could happen a district will be created without a school
    CALL district_upsert(p_district_name, p_district_natural_id, p_district_id);
    SELECT p_district_id;

    SELECT id INTO p_id FROM school WHERE natural_id = p_natural_id;

    IF (p_id IS NOT NULL)
    THEN
      -- check if there is anything to update
      SELECT CASE WHEN count(*) > 0 THEN 0 ELSE 1 END INTO isUpdate
       FROM school s JOIN district d
      WHERE s.id = p_id
            AND s.name = p_name
            AND d.natural_id = p_district_natural_id
            AND d.name = p_district_name;

      IF (isUpdate = 1)
      THEN
        UPDATE school
        SET
          name            = p_name,
          natural_id      = p_natural_id,
          district_id     = p_district_id,
          update_import_id   = p_import_id
        WHERE id = p_id;

      END IF;

    ELSE
      INSERT INTO school (district_id, name, natural_id, import_id, update_import_id)
      VALUES (p_district_id, p_name, p_natural_id, p_import_id, p_import_id);

      SELECT id INTO p_id FROM school WHERE natural_id = p_natural_id;

    END IF;
  END; //
DELIMITER ;
