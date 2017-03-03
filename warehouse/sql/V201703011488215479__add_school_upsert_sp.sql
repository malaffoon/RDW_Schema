/**
** Stored procedures to handle upsert functionality with the concurrent insert/update requests
**/

USE warehouse;

DROP PROCEDURE IF EXISTS district_upsert;

DELIMITER //
CREATE PROCEDURE district_upsert(IN  p_name       VARCHAR(60),
                                 IN  p_natural_id VARCHAR(40),
                                 OUT p_id         MEDIUMINT)
  BEGIN

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

DROP PROCEDURE IF EXISTS school_upsert;

DELIMITER //
CREATE PROCEDURE school_upsert(IN  p_district_name       VARCHAR(60),
                               IN  p_district_natural_id VARCHAR(40),
                               IN  p_name                VARCHAR(60),
                               IN  p_natural_id          VARCHAR(40),
                               OUT p_id                  MEDIUMINT)
  BEGIN
    DECLARE p_district_id MEDIUMINT;

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
      -- TODO: this needs to be revisited; afraid it is an overkill to do an update here
      UPDATE school
      SET
        name        = p_name,
        natural_id  = p_natural_id,
        district_id = p_district_id
      WHERE id = p_id;
    ELSE
      INSERT INTO school (district_id, name, natural_id)
      VALUES (p_district_id, p_name, p_natural_id);

      SELECT id INTO p_id FROM school WHERE natural_id = p_natural_id;

    END IF;
  END; //
DELIMITER ;