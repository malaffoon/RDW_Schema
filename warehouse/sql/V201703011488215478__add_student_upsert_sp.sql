/**
** Stored procedures to handle upsert functionality with the concurrent student insert/update requests
**/

USE warehouse;

DROP PROCEDURE IF EXISTS student_upsert;

DELIMITER //
CREATE PROCEDURE student_upsert (IN  p_ssid                          VARCHAR(40),
                                IN  p_last_or_surname               VARCHAR(35),
                                IN  p_first_name                    VARCHAR(35),
                                IN  p_middle_name                   VARCHAR(35),
                                IN  p_gender_id                     TINYINT,
                                IN  p_ethnicity_id                  TINYINT,
                                IN  p_first_entry_into_us_school_at DATE,
                                IN  p_lep_entry_at                  DATE,
                                IN  p_lep_exit_at                   DATE,
                                IN  p_birthday                      DATE,
                                OUT p_id                            BIGINT)
  BEGIN

    DECLARE CONTINUE HANDLER FOR 1062
    BEGIN
      SELECT id INTO p_id FROM student WHERE ssid = p_ssid;
    END;

    SELECT id INTO p_id FROM student WHERE ssid = p_ssid;

    IF (p_id IS NOT NULL)
    THEN
      UPDATE student SET
        last_or_surname               = p_last_or_surname,
        first_name                    = p_first_name,
        middle_name                   = p_middle_name,
        gender_id                     = p_gender_id,
        ethnicity_id                  = p_ethnicity_id,
        first_entry_into_us_school_at = p_first_entry_into_us_school_at,
        lep_entry_at                  = p_lep_entry_at,
        lep_exit_at                   = p_lep_exit_at,
        birthday                      = p_birthday
      WHERE id = p_id;
    ELSE
      INSERT INTO student (ssid, last_or_surname, first_name, middle_name, gender_id, ethnicity_id, first_entry_into_us_school_at, lep_entry_at, lep_exit_at, birthday)
      VALUES (p_ssid, p_last_or_surname, p_first_name, p_middle_name, p_gender_id, p_ethnicity_id, p_first_entry_into_us_school_at, p_lep_entry_at, p_lep_exit_at, p_birthday);

      SELECT id INTO p_id FROM student WHERE ssid = p_ssid;
    END IF;
  END; //
DELIMITER ;