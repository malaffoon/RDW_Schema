# IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# 1. MIGRATE SHOULD NOT BE RUNNING UNTIL THIS IS DONE
# 2. DB natural records ids seems unreliable for joining, that is why we have to use the natural ids

USE legacy_load;

DROP PROCEDURE IF EXISTS loop_by_partition;

DELIMITER //
CREATE PROCEDURE loop_by_partition(IN p_sql VARCHAR(1000), IN p_first INTEGER, IN p_last INTEGER)
  BEGIN
    DECLARE iteration INTEGER;
    SET iteration = p_first;

    partition_loop: LOOP

      SET @stmt = concat( p_sql, ' and warehouse_partition_id =', iteration);
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

########################################### variable def #####################################################################################

SET @load_id = 1;

SET @student_partition_start = 0;
SET @student_partition_end = 5;

SET @iab_partition_start = 0;
SET @iab_partition_end = 15;

########################################### pre-validation #####################################################################################
UPDATE dim_inst_hier dih
  JOIN warehouse.school ws ON dih.school_id = ws.natural_id
SET warehouse_school_id = ws.id
WHERE warehouse_load_id = @load_id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated dim_inst_hier warehouse_school_id');

# fist process asmts that we can map by the name
UPDATE dim_asmt da
  JOIN dim_asmt_guid_to_natural_id_mapping as m ON m.guid = da.asmt_guid
  JOIN warehouse.asmt wa ON wa.natural_id = m.name
SET warehouse_asmt_id = wa.id
WHERE warehouse_load_id = @load_id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated dim_asmt warehouse_asmt_id');

########################################### partition #####################################################################################
# large tables need partitioning
UPDATE dim_student ds SET warehouse_partition_id = MOD(ds.student_rec_id, @student_partition_end+1);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'partition dim_student');

UPDATE fact_block_asmt_outcome f SET warehouse_partition_id = MOD(f.asmt_outcome_rec_id, @iab_partition_end+1);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'partition fact_block_asmt_outcome');
-- NOTE: (6 min 15.67 sec)

# we do not need to partition this table but because of the missing asmt/schools this is helpful
UPDATE fact_asmt_outcome_vw f SET warehouse_partition_id = 1;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'partition fact_asmt_outcome_vw');

# move exams that are missing schools or asmts to a negative partition that will be ignored
UPDATE fact_block_asmt_outcome f
  jOIN dim_asmt a on a.asmt_guid = f.asmt_guid
  JOIN dim_inst_hier h on h.school_id =  f.school_id and h.district_id = f.district_id
SET warehouse_partition_id = -1
WHERE a.warehouse_asmt_id is null or h.warehouse_school_id is null;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'MOVED UNMAPPED DATA TO A DIFF PARTITION - TO BE REMOVED');

UPDATE fact_asmt_outcome_vw f
  jOIN dim_asmt a on a.asmt_guid = f.asmt_guid
  JOIN dim_inst_hier h on h.school_id =  f.school_id and h.district_id = f.district_id
SET warehouse_partition_id = -1
WHERE a.warehouse_asmt_id is null or h.warehouse_school_id is null;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'MOVED UNMAPPED DATA TO A DIFF PARTITION - TO BE REMOVED');

########################################### validation #######################################################################################
# TODO: if exists, then fail ?
SELECT exists(SELECT 1
              FROM dim_inst_hier
              WHERE warehouse_school_id IS NULL AND warehouse_load_id = @load_id);

SELECT exists(SELECT 1
              FROM dim_asmt
              WHERE warehouse_asmt_id IS NULL AND warehouse_load_id = @load_id);

###########################################  convert legacy codes to the warehouse codes #######################################################

CALL loop_by_partition(
    'UPDATE dim_student ds
        SET warehouse_gender_id =
          CASE WHEN ds.sex = ''male'' THEN (SELECT id FROM warehouse.gender WHERE code = ''Male'')
          ELSE (SELECT id FROM warehouse.gender WHERE CODE = ''Female'') END
      WHERE warehouse_load_id = @load_id', @student_partition_start, @student_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated dim_student warehouse_gender_id');

# TODO: legacy has two values null and t. Is null false or true? When processing TRT null is 'Complete'?
UPDATE fact_asmt_outcome_vw f
  SET warehouse_completeness_id =
    CASE WHEN f.complete = 1 THEN (SELECT id FROM warehouse.completeness WHERE code = 'Complete')
    ELSE (SELECT id FROM warehouse.completeness WHERE code = 'Partial') END
  WHERE warehouse_load_id = @load_id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated fact_asmt_outcome_vw warehouse_completeness_id');

# TODO: is this correct (here and below)
UPDATE fact_asmt_outcome_vw f
  SET warehouse_administration_condition_id =
    CASE WHEN coalesce(f.administration_condition, '') = '' THEN (SELECT id FROM warehouse.administration_condition WHERE code = 'Valid')
    ELSE (SELECT id FROM warehouse.administration_condition WHERE code = f.administration_condition) END
  WHERE warehouse_load_id = @load_id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated fact_asmt_outcome_vw warehouse_administration_condition_id');

CALL loop_by_partition(
    'UPDATE fact_block_asmt_outcome f
      SET warehouse_completeness_id =
        CASE WHEN f.complete = 1 THEN (SELECT id FROM warehouse.completeness  WHERE code = ''Complete'')
        ELSE (SELECT id FROM warehouse.completeness WHERE code = ''Partial'') END
      WHERE warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated fact_block_asmt_outcome warehouse_completeness_id');

CALL loop_by_partition(
    'UPDATE fact_block_asmt_outcome f
      SET warehouse_administration_condition_id =
        CASE WHEN coalesce(f.administration_condition, '''') = '''' THEN (SELECT id FROM warehouse.administration_condition WHERE code = ''Valid'')
        ELSE (SELECT id FROM warehouse.administration_condition WHERE code = f.administration_condition) END
      WHERE warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'updated fact_block_asmt_outcome warehouse_administration_condition_id');

########################################### validate codes conversion  #########################################################################
# TODO: if exists, then fail ?
SELECT exists(SELECT 1
              FROM dim_student
              WHERE warehouse_gender_id IS NULL AND warehouse_load_id = @load_id and warehouse_partition_id >= 0);

SELECT exists(SELECT 1
              FROM fact_asmt_outcome_vw
              WHERE warehouse_completeness_id IS NULL AND warehouse_load_id = @load_id and warehouse_partition_id >= 0);

SELECT exists(SELECT 1
              FROM fact_asmt_outcome_vw
              WHERE warehouse_administration_condition_id IS NULL AND warehouse_load_id = @load_id and warehouse_partition_id >= 0);

SELECT exists(SELECT 1
              FROM fact_block_asmt_outcome
              WHERE warehouse_completeness_id IS NULL AND warehouse_load_id = @load_id and warehouse_partition_id >= 0);

SELECT exists(SELECT 1
              FROM fact_block_asmt_outcome
              WHERE warehouse_administration_condition_id IS NULL AND warehouse_load_id = @load_id and warehouse_partition_id >= 0);

#################################### initialize import ids, we will have one per student ##################################################

# create import ids - one per student
INSERT INTO warehouse.import (status, content, contentType, digest, batch)
  SELECT
    -- we want one import id per student id
    0                     AS status,
    1                     AS content,
    'legacy load'         AS contentType,
    student_id            AS digest,
    @load_id              AS batch
  FROM dim_student ds
  WHERE warehouse_load_id = @load_id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'create warehouse import ids');

########################################### load students ###############################################################################

# assign import ids to students
CALL loop_by_partition(
    'UPDATE dim_student ds
        JOIN (SELECT
                id,
                digest AS student_id
              FROM warehouse.import
              WHERE batch = @load_id
               AND status = 0
               AND contentType = ''legacy load'') AS si
          ON si.student_id = ds.student_id
      SET ds.warehouse_import_id = si.id
      WHERE ds.warehouse_load_id = @load_id', @student_partition_start,  @student_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update dim_student with warehouse_import_id, one per student');

# NOTE: TODO this assumes we have no duplicate data loaded, for the second run maybe safer to do IGNORE?
CALL loop_by_partition(
    'INSERT INTO warehouse.student (ssid, first_name, last_or_surname, middle_name, gender_id, birthday, import_id, update_import_id)
      SELECT
        student_id,
        CASE WHEN first_name = '''' THEN null ELSE first_name END,
        CASE WHEN last_name = '''' THEN null ELSE last_name END,
        CASE WHEN middle_name = '''' THEN null ELSE middle_name END,
        warehouse_gender_id,
        CASE WHEN birthdate = '''' THEN null ELSE birthdate END,
        warehouse_import_id,
        warehouse_import_id
      FROM dim_student ds
      WHERE ds.warehouse_load_id = @load_id', @student_partition_start,  @student_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'insert new students into warehouse');

CALL loop_by_partition(
    'UPDATE dim_student ds
      JOIN warehouse.student ws on ws.ssid = ds.student_id
    SET ds.warehouse_student_id = ws.id WHERE 1 = 1', @student_partition_start,  @student_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update dim_student with warehouse_student_id');


INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'HispanicOrLatinoEthnicity') as  ethnicity_id
  from dim_student where dmg_eth_hsp = 1 and warehouse_load_id = @load_id;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'AmericanIndianOrAlaskaNative') as  ethnicity_id
  from dim_student where dmg_eth_ami = 1 and warehouse_load_id = @load_id;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'Asian') as  ethnicity_id
  from dim_student where dmg_eth_asn = 1 and warehouse_load_id = @load_id;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'BlackOrAfricanAmerican') as  ethnicity_id
  from dim_student where dmg_eth_blk = 1 and warehouse_load_id = @load_id;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'NativeHawaiianOrOtherPacificIslander') as  ethnicity_id
  from dim_student where dmg_eth_pcf = 1 and warehouse_load_id = @load_id;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'White') as  ethnicity_id
  from dim_student where dmg_eth_wht = 1 and warehouse_load_id = @load_id;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'DemographicRaceTwoOrMoreRaces') as  ethnicity_id
  from dim_student where dmg_eth_2om = 1 and warehouse_load_id = @load_id;

INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'loaded warehouse.student_ethnicity');

########################################### load ICAs  ####################################################################################

# assign import ids to ICA exams
UPDATE fact_asmt_outcome_vw f
    JOIN (SELECT
            id,
            digest AS student_id
          FROM warehouse.import
          WHERE batch = @load_id
                AND status = 0
                AND contentType = 'legacy load') AS si ON si.student_id = f.student_id
  SET f.warehouse_import_id = si.id
  WHERE f.warehouse_load_id = @load_id and warehouse_partition_id >= 0;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update fact_asmt_outcome_vw with warehouse_import_id, one per student');

# NOTE: TODO this assumes we have no duplicate data loaded, for the second run maybe safer to do IGNORE?
# Horrendous hack, but ...I am temporarily using t3_program_type to be able to relate back to the fact table
INSERT INTO warehouse.exam_student (t3_program_type, grade_id, student_id, school_id, iep, lep, section504, economic_disadvantage, migrant_status)
  SELECT
    f.asmt_outcome_vw_rec_id,
    wg.id,
    ds.warehouse_student_id,
    dh.warehouse_school_id,
    f.dmg_prg_iep,
    f.dmg_prg_lep,
    f.dmg_prg_504,
    f.dmg_sts_ecd,
    f.dmg_sts_mig
  FROM fact_asmt_outcome_vw f
    JOIN dim_student ds on ds.student_id = f.student_id
    JOIN dim_inst_hier dh on dh.school_id = f.school_id and dh.district_id = f.district_id
    JOIN warehouse.grade wg on wg.code = f.enrl_grade
  WHERE f.warehouse_load_id = @load_id and f.warehouse_partition_id >= 0;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'insert new ica exam_student into warehouse');

# assign warehouse_exam_student_id to legacy ICA exams
UPDATE fact_asmt_outcome_vw f
  JOIN ( SELECT id, cast(t3_program_type AS SIGNED) as asmt_outcome_rec_id from warehouse.exam_student)  AS wes
    ON wes.asmt_outcome_rec_id = f.asmt_outcome_vw_rec_id
SET f.warehouse_exam_student_id = wes.id
WHERE f.warehouse_load_id = @load_id and warehouse_partition_id >= 0;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update fact_asmt_outcome_vw with warehouse_exam_student_id');

# wipe out t3_program_type
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam_student SET t3_program_type = null;

# Horrendous hack again, but ...I am temporarily using session_id to be able to relate back to the fact table
# TODO: check if school_year is the correct value
INSERT INTO warehouse.exam (type_id, exam_student_id, school_year, asmt_id, completeness_id, administration_condition_id, scale_score, scale_score_std_err, performance_level, completed_at, session_id, import_id, update_import_id)
  SELECT
    1, -- ICA asmt
    f.warehouse_exam_student_id,
    f.asmt_year,
    da.warehouse_asmt_id,
    f.warehouse_completeness_id,
    f.warehouse_administration_condition_id,
    f.asmt_score,
    CASE WHEN f.asmt_score IS NOT null THEN (f.asmt_score_range_max - f.asmt_score) ELSE null END,
    f.asmt_perf_lvl,
    f.date_taken,
    f.asmt_outcome_vw_rec_id,
    f.warehouse_import_id,
    f.warehouse_import_id
  FROM fact_asmt_outcome_vw f
    JOIN dim_asmt da on da.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = @load_id and f.warehouse_partition_id >= 0;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'insert new ica exam into warehouse');

# assign warehouse_exam_id back to the fact table
UPDATE fact_asmt_outcome_vw f
  JOIN ( SELECT id, cast(session_id AS SIGNED) as asmt_outcome_rec_id from warehouse.exam)  AS we
    ON we.asmt_outcome_rec_id = f.asmt_outcome_vw_rec_id
SET f.warehouse_exam_id = we.id
WHERE f.warehouse_load_id = @load_id and f.warehouse_partition_id >= 0;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update fact_asmt_outcome_vw with warehouse_exam_id');

# replace session with 'Not Available'
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam
  SET session_id = 'Not Available';
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'reset exam_student to Not Available while processing fact_asmt_outcome_vw');

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id FROM warehouse.accommodation WHERE code = 'TDS_ASL1') AS accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_asl_video_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'ENU-Braille') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_braile_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_ClosedCap1') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_closed_captioning_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_TTS_Stim&TDS_TTS_Item') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_text_to_speech_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Abacus') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_abacus_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_AR') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_alternate_response_options_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Calc') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_calculator_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_MT') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_multiplication_table_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Stim') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_print_on_demand_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Item') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_print_on_demand_items_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_RA_Stimuli') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_read_aloud_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_SC_WritItems') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_scribe_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_STT') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_speech_to_text_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_SLM1') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_streamline_mode IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEDS_NoiseBuf') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_noise_buffer_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'loaded exam_available_accommodation for ica');

# convert legacy claim (by name) to the warehouse subject_claim_score ids
UPDATE dim_asmt
  SET warehouse_subject_claim1_score_id =
      CASE asmt_claim_1_name
          WHEN 'Concepts & Procedures' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '1' AND subject_id = 1)
          WHEN 'Problem Solving and Modeling & Data Analysis' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_2' AND subject_id = 1)
          WHEN 'Communicating Reasoning' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '3' AND subject_id = 1)
          WHEN 'Reading' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_R' AND subject_id = 2)
          WHEN 'Writing' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '2-W' AND subject_id = 2)
          WHEN 'Listening' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_LS' AND subject_id = 2)
          WHEN 'Research & Inquiry' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '4-CR' AND subject_id = 2)
          ELSE NULL
      END,
    warehouse_subject_claim2_score_id =
      CASE asmt_claim_2_name
        WHEN 'Concepts & Procedures' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '1' AND subject_id = 1)
        WHEN 'Problem Solving and Modeling & Data Analysis' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_2' AND subject_id = 1)
        WHEN 'Communicating Reasoning' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '3' AND subject_id = 1)
        WHEN 'Reading' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_R' AND subject_id = 2)
        WHEN 'Writing' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '2-W' AND subject_id = 2)
        WHEN 'Listening' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_LS' AND subject_id = 2)
        WHEN 'Research & Inquiry' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '4-CR' AND subject_id = 2)
        ELSE NULL
      END,
    warehouse_subject_claim3_score_id =
      CASE asmt_claim_3_name
        WHEN 'Concepts & Procedures' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '1' AND subject_id = 1)
        WHEN 'Problem Solving and Modeling & Data Analysis' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_2' AND subject_id = 1)
        WHEN 'Communicating Reasoning' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '3' AND subject_id = 1)
        WHEN 'Reading' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_R' AND subject_id = 2)
        WHEN 'Writing' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '2-W' AND subject_id = 2)
        WHEN 'Listening' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_LS' AND subject_id = 2)
        WHEN 'Research & Inquiry' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '4-CR' AND subject_id = 2)
        ELSE NULL
      END,
    warehouse_subject_claim4_score_id =
      CASE asmt_claim_4_name
        WHEN 'Concepts & Procedures' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '1' AND subject_id = 1)
        WHEN 'Problem Solving and Modeling & Data Analysis' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_2' AND subject_id = 1)
        WHEN 'Communicating Reasoning' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '3' AND subject_id = 1)
        WHEN 'Reading' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_R' AND subject_id = 2)
        WHEN 'Writing' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '2-W' AND subject_id = 2)
        WHEN 'Listening' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = 'SOCK_LS' AND subject_id = 2)
        WHEN 'Research & Inquiry' THEN (SELECT id FROM warehouse.subject_claim_score WHERE asmt_type_id = 1 AND code = '4-CR' AND subject_id = 2)
        ELSE NULL
    END;

# load the scores per each scorable claim
INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
    SELECT
      f.warehouse_exam_id,
      a.warehouse_subject_claim1_score_id,
      f.asmt_claim_1_score,
      CASE WHEN f.asmt_claim_1_score IS NOT null THEN (f.asmt_claim_1_score_range_max - f.asmt_claim_1_score) ELSE null END,
      f.asmt_claim_1_perf_lvl
FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
WHERE f.warehouse_load_id = @load_id and warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
  SELECT
    f.warehouse_exam_id,
    a.warehouse_subject_claim2_score_id,
    f.asmt_claim_2_score,
    CASE WHEN f.asmt_claim_2_score IS NOT null THEN (f.asmt_claim_2_score_range_max - f.asmt_claim_2_score) ELSE null END,
    f.asmt_claim_2_perf_lvl
  FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = @load_id and warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
  SELECT
    f.warehouse_exam_id,
    a.warehouse_subject_claim3_score_id,
    f.asmt_claim_3_score,
    CASE WHEN f.asmt_claim_3_score IS NOT null THEN (f.asmt_claim_3_score_range_max - f.asmt_claim_3_score) ELSE null END,
    f.asmt_claim_3_perf_lvl
  FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = @load_id and warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
  SELECT
    f.warehouse_exam_id,
    a.warehouse_subject_claim4_score_id,
    f.asmt_claim_4_score,
    CASE WHEN f.asmt_claim_4_score IS NOT null THEN (f.asmt_claim_4_score_range_max - f.asmt_claim_4_score) ELSE null END,
    f.asmt_claim_4_perf_lvl
  FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = @load_id and warehouse_partition_id >= 0 and a.asmt_subject = 'ELA';

########################################### load IABs  ###############################################################################

# assign import ids to IAB exams
CALL loop_by_partition(
    'UPDATE fact_block_asmt_outcome f
        JOIN (SELECT
                id,
                digest AS student_id
              FROM warehouse.import
              WHERE batch = @load_id
                AND status = 0
                AND contentType = ''legacy load'') AS si
          ON si.student_id = f.student_id
      SET f.warehouse_import_id = si.id
      WHERE f.warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update fact_block_asmt_outcome with warehouse_import_id, one per student');

# NOTE: TODO this assumes we have no duplicate data loaded, for the second run maybe safer to do IGNORE?
# Horrendous hack, but ...I am temporarily using t3_program_type to be able to relate back to the fact table
CALL loop_by_partition(
    'INSERT INTO warehouse.exam_student (t3_program_type, grade_id, student_id, school_id, iep, lep, section504, economic_disadvantage, migrant_status)
      SELECT
        f.asmt_outcome_rec_id,
        wg.id,
        ds.warehouse_student_id,
        dh.warehouse_school_id,
        f.dmg_prg_iep,
        f.dmg_prg_lep,
        f.dmg_prg_504,
        f.dmg_sts_ecd,
        f.dmg_sts_mig
      FROM fact_block_asmt_outcome f
        JOIN (SELECT warehouse_student_id, student_id from dim_student) as ds on ds.student_id = f.student_id
        JOIN dim_inst_hier dh on dh.school_id = f.school_id and dh.district_id = f.district_id
        JOIN warehouse.grade wg on wg.code = f.enrl_grade
      WHERE f.warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'insert new exam_student into warehouse');

# assign warehouse_exam_student_id
CALL loop_by_partition(
    'UPDATE fact_block_asmt_outcome f
        JOIN ( SELECT id, cast(t3_program_type AS SIGNED) as asmt_outcome_rec_id from warehouse.exam_student)  AS wes
          ON wes.asmt_outcome_rec_id = f.asmt_outcome_rec_id
      SET f.warehouse_exam_student_id = wes.id
      WHERE f.warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update fact_block_asmt_outcome with warehouse_exam_student_id');

# wipe out t3_program_type
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam_student SET t3_program_type = null;

# Horrendous hack again, but ...I am temporarily using session_id to be able to relate back to the fact table
# TODO: check if school_year is the correct value
CALL loop_by_partition(
    'INSERT INTO warehouse.exam (type_id, exam_student_id, school_year, asmt_id, completeness_id, administration_condition_id, scale_score, scale_score_std_err, performance_level, completed_at, session_id, import_id, update_import_id)
      SELECT
        2, -- iab assmts
        f.warehouse_exam_student_id,
        f.asmt_year,
        da.warehouse_asmt_id,
        f.warehouse_completeness_id,
        f.warehouse_administration_condition_id,
        f.asmt_claim_1_score,
        CASE WHEN f.asmt_claim_1_score IS NOT null THEN (f.asmt_claim_1_score_range_max - f.asmt_claim_1_score) ELSE null END,
        f.asmt_claim_1_perf_lvl,
        f.date_taken,
        f.asmt_outcome_rec_id,
        f.warehouse_import_id,
        f.warehouse_import_id
      FROM fact_block_asmt_outcome f
        JOIN dim_asmt da on da.asmt_guid = f.asmt_guid
      WHERE f.warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'insert new exam into warehouse');

# assign warehouse_exam_id
CALL loop_by_partition(
    'UPDATE fact_block_asmt_outcome f
        JOIN ( SELECT id, cast(session_id AS SIGNED) as asmt_outcome_rec_id from warehouse.exam)  AS we
          ON we.asmt_outcome_rec_id = f.asmt_outcome_rec_id
      SET f.warehouse_exam_id = we.id
      WHERE f.warehouse_load_id = @load_id', @iab_partition_start, @iab_partition_end);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update fact_block_asmt_outcome with warehouse_exam_id');

# replace session with 'Not Available'
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam
  SET session_id = 'Not Available';
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'reset exam_student to Not Available');

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id FROM warehouse.accommodation WHERE code = 'TDS_ASL1') AS accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_asl_video_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'ENU-Braille') as  accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_braile_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_ClosedCap1') as  accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_closed_captioning_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_TTS_Stim&TDS_TTS_Item') as  accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_text_to_speech_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Abacus') as  accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_abacus_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_AR') as  accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_alternate_response_options_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Calc') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_calculator_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_MT') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_multiplication_table_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Stim') as  accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_print_on_demand_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Item') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_print_on_demand_items_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_RA_Stimuli') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_read_aloud_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_SC_WritItems') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_scribe_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_STT') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_speech_to_text_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_SLM1') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_streamline_mode IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEDS_NoiseBuf') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_noise_buffer_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = @load_id AND warehouse_partition_id >= 0;

INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'loaded exam_available_accommodation for iab');

##########update imports as completed and reset timestamps for migrate to limit set of records in a batch ########################################
SELECT max(id) into @maxImportId from warehouse.import;

UPDATE warehouse.import
SET status = 1,
  created = DATE_ADD(created, INTERVAL (@maxImportId -id)  MICROSECOND),
  updated = DATE_ADD(updated, INTERVAL (@maxImportId -id)  MICROSECOND)
WHERE status = 0
      and content = 1
      and contentType = 'legacy load'
      and batch = @load_id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (@load_id, 'update import status to 1 for the batch');

UPDATE warehouse.student s
  JOIN warehouse.import i ON i.id = s.import_id
SET
  s.created = i.updated,
  s.updated = i.updated
WHERE i.status = 1
      and content = 1
      and contentType = 'legacy load'
      and batch = @load_id;

UPDATE warehouse.exam e
  JOIN warehouse.import i ON i.id = e.import_id
SET
  e.created = i.updated,
  e.updated = i.updated
WHERE i.status = 1
      and content = 1
      and contentType = 'legacy load'
      and batch = @load_id;

############################ to make Mark happy - remove the stored procedure so that nobody could see it ################################
DROP PROCEDURE IF EXISTS loop_by_partition;