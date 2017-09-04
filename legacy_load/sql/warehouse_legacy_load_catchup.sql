USE legacy_load;

########################################### pre-validation #####################################################################################
UPDATE dim_student_catchup sc
    LEFT JOIN dim_student s on s.student_id = sc.student_id
SET sc.load_status = 1
where s.student_id is null;

UPDATE dim_student_catchup sc
 JOIN dim_student s on s.student_id = sc.student_id
SET sc.load_status = 2 -- changes student (without ethnicity)
where
    NOT s.birthdate <=> sc.birthdate
    OR NOT s.sex  <=> sc.sex
    OR NOT s.first_name <=> sc.first_name
    OR NOT s.last_name <=> sc.last_name
    OR NOT s.middle_name <=> sc.middle_name;

UPDATE dim_student_catchup sc
 JOIN dim_student s on s.student_id = sc.student_id
SET sc.load_status = 3 -- changed ethnicity
where
    NOT s.dmg_eth_hsp <=> sc.dmg_eth_hsp
    OR NOT s.dmg_eth_ami <=> sc.dmg_eth_ami
    OR NOT s.dmg_eth_asn <=> sc.dmg_eth_asn
    OR NOT s.dmg_eth_blk <=> sc.dmg_eth_blk
    OR NOT s.dmg_eth_pcf <=> sc.dmg_eth_pcf
    OR NOT s.dmg_eth_wht <=> sc.dmg_eth_wht
    OR NOT s.dmg_eth_2om <=> sc.dmg_eth_2om;

----select count(*)
-- from dim_student_catchup sc JOIN dim_student s
-- on s.student_id = sc.student_id WHERE  NOT s.dmg_eth_hsp <=> sc.dmg_eth_hsp
--    OR NOT s.dmg_eth_ami <=> sc.dmg_eth_ami
--    OR NOT s.dmg_eth_asn <=> sc.dmg_eth_asn
--    OR NOT s.dmg_eth_blk <=> sc.dmg_eth_blk
--    OR NOT s.dmg_eth_pcf <=> sc.dmg_eth_pcf
--    OR NOT s.dmg_eth_wht <=> sc.dmg_eth_wht
--    OR NOT s.dmg_eth_2om <=> sc.dmg_eth_2om;

--select count(*)
--from dim_student_catchup sc
-- JOIN dim_student s on s.student_id = sc.student_id
-- where
--    NOT s.birthdate <=> sc.birthdate
--    OR NOT s.sex  <=> sc.sex
--    OR NOT s.first_name <=> sc.first_name
--    OR NOT s.last_name <=> sc.last_name
--    OR NOT s.middle_name <=> sc.middle_name;

# check if anything has been unchanged - just currious how many will be ignored
SELECT count(*) from  dim_student_catchup where load_status is null;

# move over new students
INSERT INTO dim_student (student_rec_id, student_id, external_student_id, first_name, middle_name, last_name, birthdate, sex, group_1_id, group_1_text, group_2_id, group_2_text, group_3_id, group_3_text, group_4_id, group_4_text, group_5_id, group_5_text, group_6_id, group_6_text, group_7_id, group_7_text, group_8_id, group_8_text, group_9_id, group_9_text, group_10_id, group_10_text, dmg_eth_derived, dmg_eth_hsp, dmg_eth_ami, dmg_eth_asn, dmg_eth_blk, dmg_eth_pcf, dmg_eth_wht, dmg_eth_2om, dmg_prg_iep, dmg_prg_lep, dmg_prg_504, dmg_sts_ecd, dmg_sts_mig, from_date, to_date, rec_status, batch_guid, warehouse_load_id)
  SELECT
    student_rec_id,
    student_id,
    external_student_id,
    first_name,
    middle_name,
    last_name,
    birthdate,
    sex,
    group_1_id,
    group_1_text,
    group_2_id,
    group_2_text,
    group_3_id,
    group_3_text,
    group_4_id,
    group_4_text,
    group_5_id,
    group_5_text,
    group_6_id,
    group_6_text,
    group_7_id,
    group_7_text,
    group_8_id,
    group_8_text,
    group_9_id,
    group_9_text,
    group_10_id,
    group_10_text,
    dmg_eth_derived,
    dmg_eth_hsp,
    dmg_eth_ami,
    dmg_eth_asn,
    dmg_eth_blk,
    dmg_eth_pcf,
    dmg_eth_wht,
    dmg_eth_2om,
    dmg_prg_iep,
    dmg_prg_lep,
    dmg_prg_504,
    dmg_sts_ecd,
    dmg_sts_mig,
    from_date,
    to_date,
    rec_status,
    batch_guid,
    100
 FROM dim_student_catchup sc
WHERE sc.load_status = 1;

INSERT INTO fact_block_asmt_outcome SELECT * FROM fact_block_asmt_outcome_100;
INSERT INTO fact_asmt_outcome_vw SELECT * FROM fact_asmt_outcome_vw_100;

########################################### pre-validation #####################################################################################
# compare counts to the expected from the legacy db
SELECT count(*) from dim_student where warehouse_load_id = 100;
SELECT count(*) from fact_block_asmt_outcome where warehouse_load_id = 100;
SELECT count(*) from fact_asmt_outcome_vw where warehouse_load_id = 100;

# verify that joins on the natural ids return the same counts as above
SELECT count(*) FROM fact_block_asmt_outcome f
  jOIN dim_asmt a on a.asmt_guid = f.asmt_guid
  JOIN dim_inst_hier h on h.school_id =  f.school_id and h.district_id = f.district_id
WHERE f.warehouse_load_id = 100 and a.warehouse_asmt_id is not null and  h.warehouse_school_id is not null;

select count(*) from fact_asmt_outcome_vw f
  jOIN dim_asmt a on a.asmt_guid = f.asmt_guid
  JOIN dim_inst_hier h on h.school_id =  f.school_id and h.district_id = f.district_id
WHERE f.warehouse_load_id = 100 and a.warehouse_asmt_id is not null and h.warehouse_school_id is not null;

###########################################  convert legacy codes to the warehouse codes #######################################################
UPDATE dim_student ds
  SET warehouse_gender_id =
          CASE WHEN ds.sex = 'male' THEN (SELECT id FROM warehouse.gender WHERE code = 'Male')
          ELSE (SELECT id FROM warehouse.gender WHERE CODE = 'Female') END
  WHERE warehouse_load_id = 100;
      
UPDATE fact_asmt_outcome_vw f
  SET warehouse_completeness_id =
    CASE WHEN f.complete = 1 THEN (SELECT id FROM warehouse.completeness WHERE code = 'Complete')
    ELSE (SELECT id FROM warehouse.completeness WHERE code = 'Partial') END
  WHERE warehouse_load_id = 100;

UPDATE fact_asmt_outcome_vw f
  SET warehouse_administration_condition_id =
    CASE WHEN coalesce(f.administration_condition, '') = '' THEN (SELECT id FROM warehouse.administration_condition WHERE code = 'Valid')
    ELSE (SELECT id FROM warehouse.administration_condition WHERE code = f.administration_condition) END
  WHERE warehouse_load_id = 100;
  
UPDATE fact_block_asmt_outcome f
   SET warehouse_completeness_id =
     CASE WHEN f.complete = 1 THEN (SELECT id FROM warehouse.completeness  WHERE code = 'Complete')
     ELSE (SELECT id FROM warehouse.completeness WHERE code = 'Partial') END
   WHERE warehouse_load_id = 100;

UPDATE fact_block_asmt_outcome f
  SET warehouse_administration_condition_id =
    CASE WHEN coalesce(f.administration_condition, '') = '' THEN (SELECT id FROM warehouse.administration_condition WHERE code = 'Valid')
    ELSE (SELECT id FROM warehouse.administration_condition WHERE code = f.administration_condition) END
  WHERE warehouse_load_id = 100;
  
########################################### validate codes conversion  #########################################################################
# TODO: if exists, then failure 
SELECT exists(SELECT 1
              FROM dim_student
              WHERE warehouse_gender_id IS NULL AND warehouse_load_id = 100);

SELECT exists(SELECT 1
              FROM fact_asmt_outcome_vw
              WHERE warehouse_completeness_id IS NULL AND warehouse_load_id = 100);

SELECT exists(SELECT 1
              FROM fact_asmt_outcome_vw
              WHERE warehouse_administration_condition_id IS NULL AND warehouse_load_id = 100);

SELECT exists(SELECT 1
              FROM fact_block_asmt_outcome
              WHERE warehouse_completeness_id IS NULL AND warehouse_load_id = 100);

SELECT exists(SELECT 1
              FROM fact_block_asmt_outcome
              WHERE warehouse_administration_condition_id IS NULL AND warehouse_load_id = 100) ;

#################################### load students ########################################################################################
####################################  handle student updates  #############################################################################

INSERT INTO warehouse.import (status, content, contentType, digest, batch)
VALUES(0, 1, 'catchup: legacy load students update', '5 students', 100);

SELECT LAST_INSERT_ID() INTO @importid;

update dim_student_catchup
 set warehouse_import_id = @importid
where load_status in (2, 3);

update dim_student_catchup sc
    join dim_student s on s.student_id = sc.student_id
set sc.warehouse_student_id = s.warehouse_student_id
where load_status in (2, 3);

update warehouse.student ws
 join dim_student_catchup sc on sc.student_id = ws.ssid
SET ws.update_import_id = sc.warehouse_import_id
where sc.load_status  in (2, 3);

update warehouse.student ws
 join dim_student_catchup sc on sc.student_id = ws.ssid
SET ws.middle_name = sc.middle_name
where sc.load_status = 2;

delete from warehouse.student_ethnicity
 where student_id in (select warehouse_student_id from dim_student_catchup where load_status = 3);

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'HispanicOrLatinoEthnicity') as  ethnicity_id
  from dim_student_catchup where dmg_eth_hsp = 1 and warehouse_load_id = 100 and load_status = 3;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'AmericanIndianOrAlaskaNative') as  ethnicity_id
  from dim_student_catchup where dmg_eth_ami = 1 and warehouse_load_id = 100 and load_status = 3;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'Asian') as  ethnicity_id
  from dim_student_catchup where dmg_eth_asn = 1 and warehouse_load_id = 100 and load_status = 3;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'BlackOrAfricanAmerican') as  ethnicity_id
  from dim_student_catchup where dmg_eth_blk = 1 and warehouse_load_id = 100 and load_status = 3;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'NativeHawaiianOrOtherPacificIslander') as  ethnicity_id
  from dim_student_catchup where dmg_eth_pcf = 1 and warehouse_load_id = 100 and load_status = 3;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'White') as  ethnicity_id
  from dim_student_catchup where dmg_eth_wht = 1 and warehouse_load_id = 100 and load_status = 3;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'DemographicRaceTwoOrMoreRaces') as  ethnicity_id
  from dim_student_catchup where dmg_eth_2om = 1 and warehouse_load_id = 100 and load_status = 3;

#################################### initialize import ids,  one per student ##############################################################
---------------------
# create import ids - one per student
INSERT INTO warehouse.import (status, content, contentType, digest, batch)
  SELECT
    -- we want one import id per student id
    0                     AS status,
    1                     AS content,
    'catchup: legacy load students'         AS contentType,
    student_id            AS digest,
    100              AS batch
  FROM dim_student ds
  WHERE warehouse_load_id = 100;

# assign import ids to students
UPDATE dim_student ds
   JOIN (SELECT id, digest AS student_id FROM warehouse.import WHERE batch = 100 AND status = 0 AND contentType = 'catchup: legacy load students') AS si
      ON si.student_id = ds.student_id
   SET ds.warehouse_import_id = si.id
  WHERE ds.warehouse_load_id = 100;
  
# load new students           
INSERT INTO warehouse.student (ssid, first_name, last_or_surname, middle_name, gender_id, birthday, import_id, update_import_id)
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
      WHERE ds.warehouse_load_id = 100;
      
UPDATE dim_student ds
      JOIN warehouse.student ws on ws.ssid = ds.student_id
  SET ds.warehouse_student_id = ws.id
  WHERE ds.warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'HispanicOrLatinoEthnicity') as  ethnicity_id
  from dim_student where dmg_eth_hsp = 1 and warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'AmericanIndianOrAlaskaNative') as  ethnicity_id
  from dim_student where dmg_eth_ami = 1 and warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'Asian') as  ethnicity_id
  from dim_student where dmg_eth_asn = 1 and warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'BlackOrAfricanAmerican') as  ethnicity_id
  from dim_student where dmg_eth_blk = 1 and warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'NativeHawaiianOrOtherPacificIslander') as  ethnicity_id
  from dim_student where dmg_eth_pcf = 1 and warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'White') as  ethnicity_id
  from dim_student where dmg_eth_wht = 1 and warehouse_load_id = 100;

INSERT INTO warehouse.student_ethnicity(student_id, ethnicity_id)
  SELECT warehouse_student_id, (SELECT id from warehouse.ethnicity where code = 'DemographicRaceTwoOrMoreRaces') as  ethnicity_id
  from dim_student where dmg_eth_2om = 1 and warehouse_load_id = 100;


# TODO: run pre/post count for total students and by ethnicity to make sure that all looks good

########################################### load ICAs  ####################################################################################
# create import ids - one per ica
INSERT INTO warehouse.import (status, content, contentType, digest, batch)
  SELECT
    -- we want one import id per exam id
    0                     AS status,
    1                     AS content,
    'catchup: legacy load ica'   AS contentType,
    asmt_outcome_vw_rec_id            AS digest,
    100              AS batch
  FROM fact_asmt_outcome_vw ds
  WHERE warehouse_load_id = 100;

########################################### load ICAs  ####################################################################################

# assign import ids to ICA exams
UPDATE fact_asmt_outcome_vw f
    JOIN (SELECT
            id,
            cast(digest AS SIGNED) as asmt_outcome_vw_rec_id
          FROM warehouse.import
          WHERE batch = 100
                AND status = 0
                AND contentType = 'catchup: legacy load ica') AS fi ON fi.asmt_outcome_vw_rec_id = f.asmt_outcome_vw_rec_id
  SET f.warehouse_import_id = fi.id
  WHERE f.warehouse_load_id = 100;

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
  WHERE f.warehouse_load_id = 100;

# assign warehouse_exam_student_id to legacy ICA exams
UPDATE fact_asmt_outcome_vw f
  JOIN ( SELECT id, cast(t3_program_type AS SIGNED) as asmt_outcome_rec_id from warehouse.exam_student)  AS wes
    ON wes.asmt_outcome_rec_id = f.asmt_outcome_vw_rec_id
SET f.warehouse_exam_student_id = wes.id
WHERE f.warehouse_load_id = 100;

# wipe out t3_program_type
UPDATE warehouse.exam_student SET t3_program_type = null where t3_program_type is not null;

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
    convert_tz(timestamp(f.date_taken), 'America/Los_Angeles', @@session.time_zone),
    f.asmt_outcome_vw_rec_id,
    f.warehouse_import_id,
    f.warehouse_import_id
  FROM fact_asmt_outcome_vw f
    JOIN dim_asmt da on da.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = 100;

# assign warehouse_exam_id back to the fact table
UPDATE fact_asmt_outcome_vw f
  JOIN ( SELECT id, cast(session_id AS SIGNED) as asmt_outcome_rec_id from warehouse.exam)  AS we
    ON we.asmt_outcome_rec_id = f.asmt_outcome_vw_rec_id
SET f.warehouse_exam_id = we.id
WHERE f.warehouse_load_id = 100;

# replace session with 'Not Available'
UPDATE warehouse.exam
  SET session_id = 'Not Available' where session_id <> 'Not Available';

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id FROM warehouse.accommodation WHERE code = 'TDS_ASL1') AS accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_asl_video_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'ENU-Braille') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_braile_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_ClosedCap1') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_closed_captioning_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_TTS_Stim&TDS_TTS_Item') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_text_to_speech_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Abacus') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_abacus_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_AR') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_alternate_response_options_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Calc') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_calculator_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_MT') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_multiplication_table_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Stim') as  accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_print_on_demand_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Item') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_print_on_demand_items_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_RA_Stimuli') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_read_aloud_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_SC_WritItems') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_scribe_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_STT') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_speech_to_text_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_SLM1') as accommodation_id
    FROM fact_asmt_outcome_vw f
  WHERE acc_streamline_mode IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

# load the scores per each scorable claim
INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
    SELECT
      f.warehouse_exam_id,
      a.warehouse_subject_claim1_score_id,
      f.asmt_claim_1_score,
      CASE WHEN f.asmt_claim_1_score IS NOT null THEN (f.asmt_claim_1_score_range_max - f.asmt_claim_1_score) ELSE null END,
      f.asmt_claim_1_perf_lvl
FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
WHERE f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
  SELECT
    f.warehouse_exam_id,
    a.warehouse_subject_claim2_score_id,
    f.asmt_claim_2_score,
    CASE WHEN f.asmt_claim_2_score IS NOT null THEN (f.asmt_claim_2_score_range_max - f.asmt_claim_2_score) ELSE null END,
    f.asmt_claim_2_perf_lvl
  FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
  SELECT
    f.warehouse_exam_id,
    a.warehouse_subject_claim3_score_id,
    f.asmt_claim_3_score,
    CASE WHEN f.asmt_claim_3_score IS NOT null THEN (f.asmt_claim_3_score_range_max - f.asmt_claim_3_score) ELSE null END,
    f.asmt_claim_3_perf_lvl
  FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_claim_score (exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category)
  SELECT
    f.warehouse_exam_id,
    a.warehouse_subject_claim4_score_id,
    f.asmt_claim_4_score,
    CASE WHEN f.asmt_claim_4_score IS NOT null THEN (f.asmt_claim_4_score_range_max - f.asmt_claim_4_score) ELSE null END,
    f.asmt_claim_4_perf_lvl
  FROM fact_asmt_outcome_vw f join dim_asmt a on a.asmt_guid = f.asmt_guid
  WHERE f.warehouse_load_id = 100 and a.asmt_subject = 'ELA';

# TODO: run pre/post counts for ICA to validate that all looks good

########################################### load IABs  ###############################################################################
#################################### initialize import ids, we will have one per iab ##################################################
INSERT INTO warehouse.import (status, content, contentType, digest, batch)
  SELECT
    -- we want one import id per exam id
    0                     AS status,
    1                     AS content,
    'catchup: legacy load iab'   AS contentType,
    asmt_outcome_rec_id            AS digest,
    100              AS batch
  FROM fact_block_asmt_outcome f
  WHERE warehouse_load_id = 100;

########################################### load IABs  ###############################################################################
UPDATE fact_block_asmt_outcome f
        JOIN (SELECT
                id,
                cast(digest AS SIGNED) as asmt_outcome_rec_id
              FROM warehouse.import
              WHERE batch = 100
                AND status = 0
                AND contentType = 'catchup: legacy load iab') AS fi ON fi.asmt_outcome_rec_id = f.asmt_outcome_rec_id
      SET f.warehouse_import_id = fi.id
      WHERE f.warehouse_load_id = 100;

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
        JOIN (SELECT warehouse_student_id, student_id from dim_student) as ds on ds.student_id = f.student_id
        JOIN dim_inst_hier dh on dh.school_id = f.school_id and dh.district_id = f.district_id
        JOIN warehouse.grade wg on wg.code = f.enrl_grade
      WHERE f.warehouse_load_id = 100;

# assign warehouse_exam_student_id
UPDATE fact_block_asmt_outcome f
        JOIN ( SELECT id, cast(t3_program_type AS SIGNED) as asmt_outcome_rec_id from warehouse.exam_student)  AS wes
          ON wes.asmt_outcome_rec_id = f.asmt_outcome_rec_id
      SET f.warehouse_exam_student_id = wes.id
      WHERE f.warehouse_load_id = 100;

# wipe out t3_program_type
# TODO: this is not safe if we have data loaded, may need to revisit for the second run
UPDATE warehouse.exam_student
    SET t3_program_type = null
    where t3_program_type is not null;

# Horrendous hack again, but ...I am temporarily using session_id to be able to relate back to the fact table
# TODO: check if school_year is the correct value
INSERT INTO warehouse.exam (type_id, exam_student_id, school_year, asmt_id, completeness_id, administration_condition_id, scale_score, scale_score_std_err, performance_level, completed_at, session_id, import_id, update_import_id)
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
        convert_tz(timestamp(f.date_taken), 'America/Los_Angeles', @@session.time_zone),
        f.asmt_outcome_rec_id,
        f.warehouse_import_id,
        f.warehouse_import_id
      FROM fact_block_asmt_outcome f
        JOIN dim_asmt da on da.asmt_guid = f.asmt_guid
      WHERE f.warehouse_load_id = 100;

# assign warehouse_exam_id
UPDATE fact_block_asmt_outcome f
        JOIN ( SELECT id, cast(session_id AS SIGNED) as asmt_outcome_rec_id from warehouse.exam)  AS we
          ON we.asmt_outcome_rec_id = f.asmt_outcome_rec_id
      SET f.warehouse_exam_id = we.id
      WHERE f.warehouse_load_id = 100;

# replace session with 'Not Available'
UPDATE warehouse.exam
  SET session_id = 'Not Available' where session_id <> 'Not Available';

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id FROM warehouse.accommodation WHERE code = 'TDS_ASL1') AS accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_asl_video_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'ENU-Braille') as  accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_braile_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_ClosedCap1') as  accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_closed_captioning_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_TTS_Stim&TDS_TTS_Item') as  accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_text_to_speech_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Abacus') as  accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_abacus_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_AR') as  accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_alternate_response_options_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_Calc') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_calculator_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_MT') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_multiplication_table_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Stim') as  accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_print_on_demand_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_PoD_Item') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_print_on_demand_items_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_RA_Stimuli') as accommodation_id
   FROM fact_block_asmt_outcome f
  WHERE acc_read_aloud_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_SC_WritItems') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_scribe_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'NEA_STT') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_speech_to_text_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;

INSERT INTO warehouse.exam_available_accommodation (exam_id, accommodation_id)
  SELECT warehouse_exam_id, (SELECT id from warehouse.accommodation where code = 'TDS_SLM1') as accommodation_id
    FROM fact_block_asmt_outcome f
  WHERE acc_streamline_mode IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND f.warehouse_load_id = 100;


##########update imports as completed and reset timestamps for migrate to limit set of records in a batch ########################################
SELECT max(id) into @maxImportId from warehouse.import;

UPDATE warehouse.import
SET status = 1,
  created = DATE_ADD(created, INTERVAL (@maxImportId -id)  MICROSECOND),
  updated = DATE_ADD(updated, INTERVAL (@maxImportId -id)  MICROSECOND)
WHERE status = 0
      and content = 1
      and contentType like 'catchup: legacy load%'
      and batch = 100;

UPDATE warehouse.student s
  JOIN warehouse.import i ON i.id = s.import_id
SET
  s.created = i.updated,
  s.updated = i.updated
WHERE i.status = 1
      and content = 1
      and contentType = 'catchup: legacy load students'
      and batch = 100;

UPDATE warehouse.student s
  JOIN warehouse.import i ON i.id = s.update_import_id
SET
  s.updated = i.updated
WHERE i.status = 1
      and content = 1
      and contentType = 'catchup: legacy load students update'
      and batch = 100;

UPDATE warehouse.exam e
  JOIN warehouse.import i ON i.id = e.import_id
SET
  e.created = i.updated,
  e.updated = i.updated
WHERE i.status = 1
      and content = 1
      and contentType like 'catchup: legacy load%'
      and batch = 100;
