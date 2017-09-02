-- create missing schools
-- this is a hack since the schools need to be created in ART

use legacy_load;

INSERT INTO warehouse.import (status, content, contentType, digest) VALUES (0, 4, 'missing legacy schools', 'missing legacy schools');
SELECT LAST_INSERT_ID() INTO @importid;

-- the only way to apply a procedure to each row in a result set is to use another procedure
DELIMITER //
CREATE PROCEDURE create_missing_schools_helper()
BEGIN
  DECLARE done TINYINT DEFAULT FALSE;
  DECLARE id INT;
  DECLARE did, sid VARCHAR(40);
  DECLARE dname, sname VARCHAR(60);
  DECLARE cur CURSOR FOR select district_id, district_name, school_id, school_name from dim_inst_hier where warehouse_school_id is null;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur;

  read_loop: LOOP
    FETCH cur INTO did, dname, sid, sname;
    IF done THEN
      LEAVE read_loop;
    END IF;
    CALL warehouse.school_upsert(dname, did, sname, sid, @importid, id);
  END LOOP;

  CLOSE cur;
END //
DELIMITER ;

CALL create_missing_schools_helper();

DROP PROCEDURE create_missing_schools_helper;

-- now we can set dim_inst_hier.warehouse_school_id for the records that were missing it
UPDATE dim_inst_hier dih
  JOIN warehouse.school ws ON dih.school_id = ws.natural_id
SET warehouse_school_id = ws.id
WHERE warehouse_load_id = 1 AND warehouse_school_id IS NULL;

UPDATE warehouse.import
 SET status = 1
WHERE id = @importid;
