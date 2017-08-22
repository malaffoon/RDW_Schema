USE legacy_load;

########################################### pre-validation ###########################################
# TODO: do we need to replace any empty values with null

UPDATE dim_inst_hier dih
  JOIN warehouse.school ws ON dih.school_id = ws.natural_id
SET warehouse_school_id = ws.id
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated dim_inst_hier warehouse_school_id');

UPDATE dim_asmt da
  JOIN dim_asmt_guid_to_natural_id_mapping m ON m.guid = da.asmt_guid
  JOIN warehouse.asmt wa ON wa.natural_id = m.natural_id
SET warehouse_asmt_id = wa.id
WHERE warehouse_load_id = 33;
INSERT INTO load_progress (warehouse_load_id, message) VALUE (33, 'updated dim_asmt warehouse_asmt_id');

UPDATE dim_student ds
SET warehouse_gender_id =
  CASE WHEN ds.sex = 'male' THEN (SELECT id FROM warehouse.gender WHERE code = 'Male')
  ELSE (SELECT id FROM warehouse.gender WHERE CODE = 'Female') END
WHERE warehouse_load_id = 33;
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

########################################### validation ###########################################
# TODO: if exists, then fail ?
SELECT exists(SELECT 1
              FROM dim_inst_hier
              WHERE warehouse_school_id IS NULL AND warehouse_load_id = 33);

SELECT exists(SELECT 1
              FROM dim_asmt
              WHERE warehouse_asmt_id IS NULL AND warehouse_load_id = 33);

SELECT exists(SELECT 1
              FROM dim_student
              WHERE warehouse_gender_id IS NULL AND warehouse_load_id = 33);

########################################### initialize import ids, we will have one per student ###########################################

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

########################################### load students ###########################################

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
########################################### load iab  ###########################################

