-- Merge the exam_student table into the exam table

USE ${schemaName};

-- disable updates to the 'updated'
ALTER TABLE exam
  MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6);

-- Copy data from exam_student to exam
ALTER TABLE exam
  ADD COLUMN grade_id tinyint,
  ADD COLUMN student_id int,
  ADD COLUMN school_id int,
  ADD COLUMN iep tinyint,
  ADD COLUMN lep tinyint,
  ADD COLUMN section504 tinyint,
  ADD COLUMN economic_disadvantage tinyint,
  ADD COLUMN migrant_status tinyint,
  ADD COLUMN eng_prof_lvl varchar(20),
  ADD COLUMN t3_program_type varchar(20),
  ADD COLUMN language_code varchar(3),
  ADD COLUMN prim_disability_type varchar(3);

-- Helper to run partitions in a loop
DELIMITER //
CREATE PROCEDURE loop_by_partition(IN p_sql VARCHAR(1000), IN p_first INTEGER, IN p_last INTEGER)
  BEGIN
    DECLARE iteration INTEGER;
    SET iteration = p_first;

    partition_loop: LOOP

      SET @stmt = concat( p_sql, ' and partition_id =', iteration);
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

-- add a partition
ALTER TABLE exam_student ADD COLUMN partition_id int;

SET @exam_student_partition_start = 0;
SET @exam_student_partition_end = 15;

UPDATE exam_student es
  SET es.partition_id = MOD(es.id, @exam_student_partition_end+1);

CALL loop_by_partition(
    'UPDATE exam e
          JOIN exam_student es ON e.exam_student_id = es.id
        SET e.grade_id            = es.grade_id,
          e.student_id            = es.student_id,
          e.school_id             = es.school_id,
          e.iep                   = es.iep,
          e.lep                   = es.lep,
          e.section504            = es.section504,
          e.economic_disadvantage = es.economic_disadvantage,
          e.migrant_status        = es.migrant_status,
          e.eng_prof_lvl          = es.eng_prof_lvl,
          e.t3_program_type       = es.t3_program_type,
          e.language_code         = es.language_code,
          e.prim_disability_type  = es.prim_disability_type
        WHERE 1=1', @exam_student_partition_start, @exam_student_partition_end);

-- enable constraints
ALTER TABLE exam
  MODIFY COLUMN grade_id tinyint NOT NULL,
  MODIFY COLUMN student_id int NOT NULL,
  MODIFY COLUMN school_id int NOT NULL,
  MODIFY COLUMN iep tinyint NOT NULL,
  MODIFY COLUMN lep tinyint NOT NULL,
  MODIFY COLUMN economic_disadvantage tinyint NOT NULL,
  ADD INDEX idx__exam__student (student_id),
  ADD INDEX idx__exam__school (school_id),
  ADD CONSTRAINT fk__exam__student FOREIGN KEY (student_id) REFERENCES student(id),
  ADD CONSTRAINT fk__exam__school FOREIGN KEY (school_id) REFERENCES school(id);

-- clean up
DROP PROCEDURE loop_by_partition;

ALTER TABLE exam DROP FOREIGN KEY fk__exam__exam_student;
ALTER TABLE exam DROP INDEX idx__exam__exam_student;
ALTER TABLE exam DROP COLUMN exam_student_id;

-- enable auto updates to the 'updated'
ALTER TABLE exam
    MODIFY COLUMN updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);

DROP TABLE exam_student;