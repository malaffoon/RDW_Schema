USE ${schemaName};

ALTER TABLE student
  MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  ADD COLUMN partition_id INT,
  ADD INDEX idx__student__partition_id (partition_id);

SET @student_partition_start = 0;
SET @student_partition_end = 99;

UPDATE student s SET s.partition_id = MOD(s.id, @student_partition_end + 1);

-- one import record per student
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT 0, 1, 'initial load of inferred schools', 'initial load of inferred schools', id from student;

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
      JOIN (SELECT id, cast(batch AS UNSIGNED) student_id FROM import where digest = ''initial load of inferred schools'' and status = 0) i ON s.id = i.student_id
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

SELECT max(id) into @maxImportId from import;

-- distribute imports for migrate to have smaller chunks
UPDATE import
SET status = 1,
  created = DATE_ADD(created, INTERVAL (@maxImportId -id)  MICROSECOND),
  updated = DATE_ADD(updated, INTERVAL (@maxImportId -id)  MICROSECOND)
WHERE status = 0
      and content = 1
      and digest = 'initial load of inferred schools';

-- update date to match imports
UPDATE student s
  JOIN import i ON i.id = s.update_import_id
SET
  s.updated = i.updated
WHERE i.status = 1
      and content = 1
      and digest = 'initial load of inferred schools';

-- revert temporary changes
ALTER TABLE student
  MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  DROP INDEX idx__student__partition_id,
  DROP COLUMN partition_id;

