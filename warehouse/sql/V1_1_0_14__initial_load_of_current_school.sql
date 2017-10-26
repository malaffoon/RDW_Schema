USE ${schemaName};

ALTER TABLE student
  ADD COLUMN partition_id INT,
  ADD INDEX idx__student__partition_id (partition_id);

SET @student_partition_start = 0;
SET @student_partition_end = 100;

UPDATE student s SET s.partition_id = MOD(s.id, @student_partition_end + 1);

INSERT INTO import (status, content, contentType, digest, batch)
 SELECT DISTINCT 0, 4, 'missing legacy schools', 'missing legacy schools', partition_id from student;

-- Helper to run partitions in a loop
DELIMITER //
CREATE PROCEDURE loop_by_partition(IN p_sql VARCHAR(1000), IN p_first INTEGER, IN p_last INTEGER)
  BEGIN
    DECLARE iteration INTEGER;
    SET iteration = p_first;

    partition_loop: LOOP

      SET @stmt = concat(p_sql, ' and s.partition_id =', iteration);
      PREPARE stmt FROM @stmt;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT concat('executed partition:', iteration);

      SET iteration = iteration + 1;
      IF iteration <= p_last
      THEN
        ITERATE partition_loop;
      END IF;
      LEAVE partition_loop;
    END LOOP partition_loop;

  END;
//
DELIMITER ;

-- NOTE that this does not account for DELETED exams assuming that we do not have a case when deleted exam has the most recent completed_at
CALL loop_by_partition(
    'UPDATE student s
      JOIN (SELECT id, cast(batch AS UNSIGNED) partition_id FROM import) i ON s.partition_id = i.partition_id
      JOIN exam AS e1 ON s.id = e1.student_id
      LEFT OUTER JOIN exam AS e2 ON e1.student_id = e2.student_id
           AND (e1.completed_at < e2.completed_at OR (e1.completed_at = e2.completed_at AND e1.Id < e2.Id))
    SET
      s.inferred_effective_date = e1.completed_at,
      s.inferred_school_id      = e1.school_id,
      s.update_import_id        = i.id
    WHERE e2.student_id IS NULL ',
    @student_partition_start, @student_partition_end);

DROP PROCEDURE loop_by_partition;

ALTER TABLE student
  DROP INDEX idx__student__partition_id,
  DROP COLUMN partition_id;

UPDATE import SET status = 1 WHERE contentType = 'missing legacy schools';
