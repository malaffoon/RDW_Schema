USE legacy_load;


DROP PROCEDURE IF EXISTS loop_by_partition;

DELIMITER //
CREATE PROCEDURE loop_by_partition(IN p_sql VARCHAR(1000), IN p_size INTEGER)
  BEGIN
    DECLARE iteration INTEGER;
    SET iteration = 0;

    label1: LOOP
      SET iteration = iteration + 1;
      SET @stmt = concat( p_sql, ' and warehouse_partition_id =', iteration);
      PREPARE stmt FROM @stmt;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      SELECT concat('executed partition:', iteration);

      IF iteration < p_size THEN
        ITERATE label1;
      END IF;
      LEAVE label1;
    END LOOP label1;
  END;
//
DELIMITER ;


########################################### pre-validation #####################################################################
# TODO: do we need to replace any empty values with null

UPDATE dim_inst_hier dih
  JOIN warehouse.school ws ON dih.school_id = ws.natural_id
SET warehouse_school_id = ws.id
WHERE warehouse_load_id = 33;

INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated dim_inst_hier warehouse_school_id');

UPDATE dim_asmt da
  JOIN (select concat('(SBAC)', natural_id, '-Winter-', school_year) as natural_id, guid from  dim_asmt_guid_to_natural_id_mapping ) as m ON m.guid = da.asmt_guid -- TODO: this needs to be adjusted
  JOIN warehouse.asmt wa ON wa.natural_id = m.natural_id
SET warehouse_asmt_id = wa.id
WHERE warehouse_load_id = 33;

# some asmt_guid are not guids
UPDATE dim_asmt da
  JOIN (select asmt_rec_id, concat('(SBAC)', asmt_guid, '-Winter-', asmt_period_year, '-', asmt_period_year+1) as natural_id from  dim_asmt ) as m ON m.asmt_rec_id = da.asmt_rec_id -- TODO: this needs to be adjusted
  JOIN warehouse.asmt wa ON wa.natural_id = m.natural_id
SET warehouse_asmt_id = wa.id
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated dim_asmt warehouse_asmt_id');

# partition
UPDATE dim_student ds
  SET warehouse_partition_id = MOD(ds.student_rec_id, 5);

CALL loop_by_partition('UPDATE dim_student ds
SET warehouse_gender_id =
CASE WHEN ds.sex = ''male'' THEN (SELECT id FROM warehouse.gender WHERE code = ''Male'')
ELSE (SELECT id FROM warehouse.gender WHERE CODE = ''Female'') END
WHERE warehouse_load_id = 33', 5);
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated dim_student warehouse_gender_id');

# TODO: legacy has two values null and t. Is null false or true? When processing TRT null is 'Complete'?
UPDATE fact_asmt_outcome_vw f
SET warehouse_completeness_id =
CASE WHEN f.complete = 't' THEN (SELECT id FROM warehouse.completeness WHERE code = 'Complete')
ELSE (SELECT id FROM warehouse.completeness WHERE code = 'Partial') END
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated fact_asmt_outcome_vw warehouse_completeness_id');

# TODO: is this correct (here and below)
UPDATE fact_asmt_outcome_vw f
SET warehouse_administration_condition_id =
CASE WHEN coalesce(f.administration_condition, '') = '' THEN (SELECT id FROM warehouse.administration_condition WHERE code = 'Valid')
ELSE (SELECT id FROM warehouse.administration_condition WHERE code = f.administration_condition) END
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated fact_asmt_outcome_vw warehouse_administration_condition_id');

UPDATE fact_block_asmt_outcome f
SET warehouse_completeness_id =
CASE WHEN f.complete = 't' THEN (SELECT id FROM warehouse.completeness  WHERE code = 'Complete')
ELSE (SELECT id FROM warehouse.completeness WHERE code = 'Partial') END
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated fact_block_asmt_outcome warehouse_completeness_id');

UPDATE fact_block_asmt_outcome f
SET warehouse_administration_condition_id =
CASE WHEN coalesce(f.administration_condition, '') = '' THEN (SELECT id FROM warehouse.administration_condition WHERE code = 'Valid')
ELSE (SELECT id FROM warehouse.administration_condition WHERE code = f.administration_condition) END
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated fact_block_asmt_outcome warehouse_administration_condition_id');

########################################### validation ###############################################################################
# TODO: if exists, then fail ?
SELECT exists(SELECT 1
              FROM dim_inst_hier
              WHERE warehouse_school_id IS NULL AND warehouse_load_id = 33);


SELECT exists(SELECT 1
              FROM dim_asmt
              WHERE warehouse_asmt_id IS NULL AND warehouse_load_id = 33);

#################################### initialize import ids, we will have one per student ###########################################

# create import ids - one per student
INSERT INTO warehouse.import (status, content, contentType, digest, batch)
  SELECT
    -- we want one import id per student id
    0                     AS status,
    1                     AS content,
    'legacy load student' AS contentType,
    student_id            AS digest,
    33                    AS batch
  FROM dim_student ds
  WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'create warehouse import ids');

########################################### load students #######################################################################

# assign import ids students
UPDATE dim_student ds
  JOIN (SELECT
          id,
          digest AS student_id
        FROM warehouse.import
        WHERE batch = '33' AND status = 0 AND contentType = 'legacy load student') AS si
    ON si.student_id = ds.student_id
SET ds.warehouse_import_id = si.id
WHERE ds.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'update dim_student with warehouse_import_id, one per student');

# NOTE: TODO this assumes we have no duplicate data loaded, for the second run maybe safer to do IGNORE?
INSERT INTO warehouse.student (ssid, first_name, last_or_surname, middle_name, gender_id, birthday, import_id, update_import_id) -- TODO: remove gender once a bug is fixed
  SELECT
    student_id,
    first_name,
    last_name,
    middle_name,
    warehouse_gender_id,
    birthdate, -- TODO: check that it loads dates properly
    warehouse_import_id,
    warehouse_import_id
  FROM dim_student ds
  WHERE ds.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'insert new students into warehouse');

UPDATE dim_student ds
  JOIN warehouse.student ws on ws.ssid = ds.student_id
SET ds.warehouse_student_id = ws.id;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'update dim_student with warehouse_student_id');


INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'HispanicOrLatinoEthnicity') as  ethnicity_id
  from dim_student where dmg_eth_hsp = 1;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'AmericanIndianOrAlaskaNative') as  ethnicity_id
  from dim_student where dmg_eth_ami = 1;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'Asian') as  ethnicity_id
  from dim_student where dmg_eth_asn = 1;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'BlackOrAfricanAmerican') as  ethnicity_id
  from dim_student where dmg_eth_blk = 1;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'NativeHawaiianOrOtherPacificIslander') as  ethnicity_id
  from dim_student where dmg_eth_pcf = 1;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'White') as  ethnicity_id
  from dim_student where dmg_eth_wht = 1;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'DemographicRaceTwoOrMoreRaces') as  ethnicity_id
  from dim_student where dmg_eth_2om = 1;

INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'loaded warehouse.student_ethnicity');

########################################### load iab  #######################################################################

# assign import ids iab exams
UPDATE fact_block_asmt_outcome f
  JOIN (SELECT
          id,
          digest AS student_id
        FROM warehouse.import
        WHERE batch = '33' AND status = 0 AND contentType = 'legacy load student') AS si
    ON si.student_id = f.student_id
SET f.warehouse_import_id = si.id
WHERE f.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'update fact_block_asmt_outcome with warehouse_import_id, one per student');

# NOTE: TODO this assumes we have no duplicate data loaded, for the second run maybe safer to do IGNORE?
# Horrendous hack, but ...I am temporarily using t3_program_type to be able to relate back to the fact table
INSERT INTO warehouse.exam_student (t3_program_type, grade_id, student_id, school_id, iep, lep, section504, economic_disadvantage, migrant_status)
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
    JOIN dim_student ds on ds.student_rec_id = f.student_rec_id
    JOIN dim_inst_hier dh on dh.inst_hier_rec_id = f.inst_hier_rec_id
    JOIN warehouse.grade wg on wg.code = f.enrl_grade
  WHERE ds.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'insert new exam_student into warehouse');

# assign warehouse_exam_student_id iab exams
UPDATE fact_block_asmt_outcome f
  JOIN ( SELECT id, cast(t3_program_type AS SIGNED) as asmt_outcome_rec_id from warehouse.exam_student)  AS wes
    ON wes.asmt_outcome_rec_id = f.asmt_outcome_rec_id
SET f.warehouse_exam_student_id = wes.id
WHERE f.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'update fact_block_asmt_outcome with warehouse_exam_student_id');

# wipe out t3_program_type
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam_student
SET t3_program_type = null;

# Horrendous hack again, but ...I am temporarily using session_id to be able to relate back to the fact table
INSERT INTO warehouse.exam (type_id, exam_student_id, school_year, asmt_id, completeness_id, administration_condition_id, scale_score, scale_score_std_err, performance_level, completed_at, session_id, import_id, update_import_id)
  SELECT
    2,
    f.warehouse_exam_student_id,
    f.asmt_year, -- TODO: check if this it the year we want (last number from the academic year)
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
    JOIN dim_asmt da on da.asmt_rec_id = f.asmt_rec_id
  WHERE f.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'insert new exam into warehouse');

# assign warehouse_exam_id iab exams
UPDATE fact_block_asmt_outcome f
  JOIN ( SELECT id, cast(session_id AS SIGNED) as asmt_outcome_rec_id from warehouse.exam)  AS we
    ON we.asmt_outcome_rec_id = f.asmt_outcome_rec_id
SET f.warehouse_exam_id = we.id
WHERE f.warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'update fact_block_asmt_outcome with warehouse_exam_id');

# replace session with 'unknown'
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam_student
SET t3_program_type = 'unknown';
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'reset exam_student to unknown');


INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_ASL1') as  accommodation_id
  from fact_block_asmt_outcome f where acc_asl_video_embed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'ENU-Braille') as  accommodation_id
  from fact_block_asmt_outcome f where acc_braile_embed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_ClosedCap1') as  accommodation_id
  from fact_block_asmt_outcome f where acc_closed_captioning_embed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_TTS_Stim&amp;TDS_TTS_Item') as  accommodation_id
  from fact_block_asmt_outcome f where acc_text_to_speech_embed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Abacus') as  accommodation_id
  from fact_block_asmt_outcome f where acc_abacus_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_AR') as  accommodation_id
  from fact_block_asmt_outcome f where acc_alternate_response_options_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Calc') as  accommodation_id
  from fact_block_asmt_outcome f where acc_calculator_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_MT') as  accommodation_id
  from fact_block_asmt_outcome f where acc_multiplication_table_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Stim') as  accommodation_id
  from fact_block_asmt_outcome f where acc_print_on_demand_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Item') as  accommodation_id
  from fact_block_asmt_outcome f where acc_print_on_demand_items_nonembed  in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_RA_Stimuli') as  accommodation_id
  from fact_block_asmt_outcome f where acc_read_aloud_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_SC_WritItems') as  accommodation_id
  from fact_block_asmt_outcome f where acc_scribe_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_STT') as  accommodation_id
  from fact_block_asmt_outcome f where acc_speech_to_text_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_SLM1') as  accommodation_id
  from fact_block_asmt_outcome f where acc_streamline_mode in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEDS_NoiseBuf') as  accommodation_id
  from fact_block_asmt_outcome f where acc_noise_buffer_nonembed in (6, 7, 8, 15, 16, 17, 24, 25, 26);

INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'loaded exam_available_accommodation for iab');


########################################### load ica  ############################################################################

# TODO - complete when iab is tested, the only difference is that we need to include claim scores


########################################### update imports as completed  #########################################################
UPDATE warehouse.import
SET status = 1
WHERE status = 0 and content = 1 and contentType = 'legacy load student' and batch = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'update import status to 1 for the batch');
