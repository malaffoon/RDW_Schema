-- Correct exam.oppId conflicts:
-- 1: Generate oppIds for legacy data with NULL values
-- 2: Dissociate exams with the same asmt_id, oppId, student_id by modifying
--    their existing oppId values

USE ${schemaName};

-- Helper to run partitions in a loop
DELIMITER //
CREATE PROCEDURE loop_by_partition(IN p_sql VARCHAR(1000), IN p_first INTEGER, IN p_last INTEGER)
  BEGIN
    DECLARE iteration INTEGER;
    SET iteration = p_first;

    partition_loop: LOOP

      SET @stmt = concat( p_sql, ' and e1.partition_id =', iteration);
      PREPARE stmt FROM @stmt;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT concat('executed partition:', iteration);

      SET iteration = iteration + 1;
      IF iteration <= p_last THEN
        ITERATE partition_loop;
      END IF;
      LEAVE partition_loop;
    END LOOP partition_loop;

  END;
//
DELIMITER ;

-- disable updates to the 'updated' and add a partition and index for processing
ALTER TABLE exam
  MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  ADD INDEX idx__exam__asmt_id_student_id_oppId (asmt_id, student_id, oppId),
  ADD COLUMN partition_id int;

SET @exam_student_partition_start = 0;
SET @exam_student_partition_end = 15;

UPDATE exam e
  SET e.partition_id = MOD(e.id, @exam_student_partition_end+1);

-- Dissociate duplicates
CALL loop_by_partition(
    'UPDATE exam e1
      JOIN exam e2 ON e2.id != e1.id
        AND e2.asmt_id = e1.asmt_id
        AND e2.student_id = e1.student_id
        AND e2.oppId = e1.oppId
    SET e1.oppId = CONCAT(CAST(e1.id as CHAR), ''_'', e1.oppId)
    WHERE e1.oppId IS NOT NULL', @exam_student_partition_start, @exam_student_partition_end);

-- Populate null values
CALL loop_by_partition(
    'UPDATE exam e1
        SET e1.oppId = CONCAT(\'legacy_\', CAST(e1.id as CHAR))
        WHERE e1.oppId IS NULL', @exam_student_partition_start, @exam_student_partition_end);

-- clean up
DROP PROCEDURE loop_by_partition;

-- enable auto updates to the 'updated'
ALTER TABLE exam
  MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  DROP COLUMN partition_id,
  DROP INDEX idx__exam__asmt_id_student_id_oppId;

-- add unique index on exam key properties
ALTER TABLE exam
  ADD UNIQUE INDEX idx__exam__asmt_id_student_id_oppId (asmt_id, student_id, oppId);