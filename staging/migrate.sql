use staging;
-- -----------------------------------------------------------------------------------------
-- MOVE FROM WAREHOUSE TO STAGING
-- -----------------------------------------------------------------------------------------
-- TODO: this is a temp hack/simulation that I needed to test
TRUNCATE TABLE reporting.migrate;
-- In the real life this will be done at the beginning of the migration
INSERT INTO reporting.migrate (id, status, first_import_id, last_import_id)
VALUES (11, 10, 100, 1100);

-- TODO: the steps below will be controlled by the migrate job and will be driven by the type of the import content
-- -----------------------------------------------------------------------------------------
-- clean up
-- -----------------------------------------------------------------------------------------
TRUNCATE TABLE staging_subject;
TRUNCATE TABLE staging_grade;
TRUNCATE TABLE staging_asmt_type;
TRUNCATE TABLE staging_completeness;
TRUNCATE TABLE staging_administration_condition;
TRUNCATE TABLE staging_ethnicity;
TRUNCATE TABLE staging_gender;
TRUNCATE TABLE staging_accommodation;
TRUNCATE TABLE staging_claim;
TRUNCATE TABLE staging_subject_claim_score;
TRUNCATE TABLE staging_target;
TRUNCATE TABLE staging_depth_of_knowledge;
TRUNCATE TABLE staging_math_practice;
TRUNCATE TABLE staging_item_trait_score;
TRUNCATE TABLE staging_item_difficulty_cuts;

TRUNCATE TABLE staging_school;
TRUNCATE TABLE staging_district;

TRUNCATE TABLE staging_student;
TRUNCATE TABLE staging_student_ethnicity;

TRUNCATE TABLE staging_asmt;
TRUNCATE TABLE staging_asmt_score;
TRUNCATE TABLE staging_item;

-- ----------------------------------------------------------------------
-- load data into staging table
-- ----------------------------------------------------------------------

-- Codes  ---------------------------------------------------------------
-- Codes do not have import ids or delete flag.
-- Since this should be a very infrequent event, we will just synchronize all the data
-- It is assumed that the data warehouse does all the hard work of insuring that
-- nothing will break if a code is modified
INSERT INTO staging_subject (id, name)
  SELECT id, name from warehouse.subject;

INSERT INTO staging_grade (id, code, name)
  SELECT id, code, name from warehouse.grade;

INSERT INTO staging_asmt_type (id, code, name)
  SELECT id, code, name from warehouse.asmt_type;

INSERT INTO staging_completeness (id, name)
  SELECT id, name from warehouse.completeness;

INSERT INTO staging_administration_condition (id, name)
  SELECT id, name from warehouse.administration_condition;

INSERT INTO staging_ethnicity (id, name)
  SELECT id, name from warehouse.ethnicity;

INSERT INTO staging_gender (id, name)
  SELECT id, name from warehouse.gender;

INSERT INTO staging_accommodation (id, code)
  SELECT id, code from warehouse.accommodation;

INSERT INTO staging_claim (id, subject_id, code, name, description)
  SELECT id, subject_id, code, name, description from warehouse.claim;

INSERT INTO staging_subject_claim_score (id, subject_id, asmt_type_id, code, name)
  SELECT id, subject_id, asmt_type_id, code, name from warehouse.subject_claim_score;

INSERT INTO staging_target (id, claim_id, code, description)
  SELECT id, claim_id, code, description from warehouse.target;

INSERT INTO staging_depth_of_knowledge (id, level, subject_id, description, reference)
  SELECT id, level, subject_id, description, reference from warehouse.depth_of_knowledge;

INSERT INTO staging_math_practice (practice, description)
  SELECT practice, description from warehouse.math_practice;

INSERT INTO staging_item_trait_score (id, dimension)
  SELECT id, dimension from warehouse.item_trait_score;

INSERT INTO staging_item_difficulty_cuts (id, asmt_type_id, subject_id,grade_id, moderate_low_end, difficult_low_end)
  SELECT id, asmt_type_id, subject_id,grade_id, moderate_low_end, difficult_low_end from warehouse.item_difficulty_cuts;

-- School  --------------------------------------------------------------

-- this includes updates/inserts but not deletes
INSERT INTO staging_district (id, natural_id, name, migrate_id)
  SELECT
    wd.id,
    wd.natural_id,
    wd.name,
    11 -- TODO: this id will be passed in from the previous migrate task
  FROM warehouse.district wd
  WHERE EXISTS(
      SELECT id from warehouse.school ws
      WHERE district_id = wd.id
            AND ws.deleted = 0 -- delete will be taken care on the 'master' level
            -- TODO: this ids will be passed in from the previous migrate task
            AND import_id  IN ( SELECT id FROM warehouse.import WHERE id >= -1));

INSERT INTO staging_school (id, natural_id, name, import_id, deleted, district_id, migrate_id)
  SELECT
    ws.id,
    ws.natural_id,
    ws.name,
    ws.import_id,
    ws.deleted,
    ws.district_id,
    11 -- TODO: this id will be passed in from the previous migrate task
  FROM warehouse.school ws
    JOIN warehouse.district wd ON wd.id = ws.district_id
  WHERE
    -- TODO: this ids will be passed in from the previous migrate task
    ws.import_id IN (SELECT id FROM warehouse.import WHERE id >= -1);

-- Student  ---------------------------------------------------------------------------------
INSERT INTO staging_student (id, ssid, last_or_surname, first_name, middle_name, gender_id, first_entry_into_us_school_at,
                             lep_entry_at, lep_exit_at, birthday, import_id, deleted, migrate_id)
  SELECT
    ws.id,
    ws.ssid,
    ws.last_or_surname,
    ws.first_name,
    ws.middle_name,
    ws.gender_id,
    ws.first_entry_into_us_school_at,
    ws.lep_entry_at,
    ws.lep_exit_at,
    ws.birthday,
    ws.import_id,
    ws.deleted,
    11 -- TODO: this id will be passed in from the previous migrate task
  FROM warehouse.student ws
  WHERE
    -- TODO: this ids will be passed in from the previous migrate task
    ws.import_id IN (SELECT id FROM warehouse.import WHERE id >= -1);

-- this includes updates/inserts but not deletes
INSERT INTO staging_student_ethnicity (id, ethnicity_id, student_id)
  SELECT
    wse.id,
    wse.ethnicity_id,
    wse.student_id
  FROM warehouse.student_ethnicity wse
    JOIN warehouse.student ws ON ws.id = wse.student_id
  WHERE
    -- TODO: this ids will be passed in from the previous migrate task
    ws.import_id IN (SELECT id FROM warehouse.import WHERE id >= -1)
    AND ws.deleted = 0;  -- delete will be taken care on the 'master' level

-- Assessment ------------------------------------------------------------------------------

INSERT INTO staging_asmt ( id, natural_id, grade_id, type_id, subject_id, school_year, name,
                           label, version, import_id, deleted, migrate_id)
  SELECT
    wa.id,
    wa.natural_id,
    wa.grade_id,
    wa.type_id,
    wa.subject_id,
    wa.school_year,
    wa.name,
    wa.label,
    wa.version,
    wa.import_id,
    wa.deleted,
    11 -- TODO: this id will be passed in from the previous migrate task
  FROM warehouse.asmt wa
  WHERE
    -- TODO: this ids will be passed in from the previous migrate task
    wa.import_id IN (SELECT id FROM warehouse.import WHERE id >= -1);

-- this includes updates/inserts but not deletes
INSERT INTO staging_asmt_score ( asmt_id, cut_point_1, cut_point_2, cut_point_3, min_score, max_score, migrate_id)
  SELECT
    was.asmt_id,
    was.cut_point_1,
    was.cut_point_2,
    was.cut_point_3,
    was.min_score,
    was.max_score,
    11 -- TODO: this id will be passed in from the previous migrate task
  FROM warehouse.asmt_score  was
    JOIN warehouse.asmt wa ON wa.id = was.asmt_id
  WHERE
    -- TODO: this ids will be passed in from the previous migrate task
    wa.import_id IN (SELECT id FROM warehouse.import WHERE id >= -1)
    AND wa.deleted = 0;  -- delete will be taken care on the 'master' level

INSERT INTO staging_item ( id, claim_id, target_id, natural_id, asmt_id, math_practice, allow_calc, dok_id,
                           difficulty, max_points, migrate_id)
  SELECT
    wi.id,
    wi.claim_id,
    wi.target_id,
    wi.natural_id,
    wi.asmt_id,
    wi.math_practice,
    wi.allow_calc,
    wi.dok_id,
    wi.difficulty,
    wi.max_points,
    11 -- TODO: this id will be passed in from the previous migrate task
  FROM warehouse.item  wi
    JOIN warehouse.asmt wa ON wa.id = wi.asmt_id
  WHERE
    -- TODO: this ids will be passed in from the previous migrate task
    wa.import_id IN (SELECT id FROM warehouse.import WHERE id >= -1)
    AND wa.deleted = 0;  -- delete will be taken care on the 'master' level

-- -----------------------------------------------------------------------------------------
-- MOVE FROM STAGING TO REPORTING
-- -----------------------------------------------------------------------------------------

-- Codes  ----------------------------------------------------------------------------------
-- the following three steps should be repeated for each code table
-- step 1: update existing codes
-- step 2: insert new codes
-- step 3: remove codes that do not exists in the staging/warehouse

-- ------------ Subject --------------------------------------------------------------------
UPDATE reporting.subject rs
  JOIN staging_subject ss ON ss.id = rs.id
SET
  rs.name = ss.name;

INSERT INTO reporting.subject ( id, name)
  SELECT
    ss.id,
    ss.name
  FROM staging_subject ss
    LEFT JOIN reporting.subject rs ON rs.id = ss.id
  WHERE rs.id IS NULL;

DELETE rs FROM reporting.subject rs
WHERE NOT EXISTS(SELECT id FROM staging_subject WHERE id = rs.id);


-- ------------ Grade --------------------------------------------------------------------
UPDATE reporting.grade rg
  JOIN staging_grade sg ON sg.id = rg.id
SET
  rg.name = sg.name,
  rg.code = sg.code;

INSERT INTO reporting.grade ( id, code, name)
  SELECT
    sg.id,
    sg.code,
    sg.name
  FROM staging_grade sg
    LEFT JOIN reporting.grade rg ON rg.id = sg.id
  WHERE rg.id IS NULL;

DELETE rg FROM reporting.grade rg
WHERE NOT EXISTS(SELECT id FROM staging_grade WHERE id = rg.id);

-- ------------ Asmt Type --------------------------------------------------------------------
UPDATE reporting.asmt_type rat
  JOIN staging_asmt_type sat ON sat.id = rat.id
SET
  rat.name = sat.name,
  rat.code = sat.code;

INSERT INTO reporting.asmt_type ( id, code, name)
  SELECT
    sat.id,
    sat.code,
    sat.name
  FROM staging_asmt_type sat
    LEFT JOIN reporting.asmt_type rat ON rat.id = sat.id
  WHERE rat.id IS NULL;

DELETE rat FROM reporting.asmt_type rat
WHERE NOT EXISTS(SELECT id FROM staging_asmt_type WHERE id = rat.id);


-- ------------ Completeness --------------------------------------------------------------------
UPDATE reporting.completeness rc
  JOIN staging_completeness sc ON sc.id = rc.id
SET
  rc.name = sc.name;

INSERT INTO reporting.completeness ( id, name)
  SELECT
    sc.id,
    sc.name
  FROM staging_completeness sc
    LEFT JOIN reporting.completeness rc ON rc.id = sc.id
  WHERE rc.id IS NULL;

DELETE rc FROM reporting.completeness rc
WHERE NOT EXISTS(SELECT id FROM staging_completeness WHERE id = rc.id);


-- ------------ Administration Condition ---------------------------------------------------------
UPDATE reporting.administration_condition rac
  JOIN staging_administration_condition sac ON sac.id = rac.id
SET
  rac.name = sac.name;

INSERT INTO reporting.administration_condition ( id, name)
  SELECT
    sac.id,
    sac.name
  FROM staging_administration_condition sac
    LEFT JOIN reporting.administration_condition rac ON rac.id = sac.id
  WHERE rac.id IS NULL;

DELETE rac FROM reporting.administration_condition rac
WHERE NOT EXISTS(SELECT id FROM staging_administration_condition WHERE id = rac.id);


-- ------------ Ethnicity ------------------------------------------------------------------------
UPDATE reporting.ethnicity re
  JOIN staging_ethnicity se ON se.id = re.id
SET
  re.name = se.name;

INSERT INTO reporting.ethnicity ( id, name)
  SELECT
    se.id,
    se.name
  FROM staging_ethnicity se
    LEFT JOIN reporting.ethnicity re ON re.id = se.id
  WHERE re.id IS NULL;

DELETE re FROM reporting.ethnicity re
WHERE NOT EXISTS(SELECT id FROM staging_ethnicity WHERE id = re.id);


-- ------------ Gender ------------------------------------------------------------------------
UPDATE reporting.gender rg
  JOIN staging_gender sg ON sg.id = rg.id
SET
  rg.name = sg.name;

INSERT INTO reporting.gender ( id, name)
  SELECT
    sg.id,
    sg.name
  FROM staging_gender sg
    LEFT JOIN reporting.gender rg ON rg.id = sg.id
  WHERE rg.id IS NULL;

DELETE rg FROM reporting.gender rg
WHERE NOT EXISTS(SELECT id FROM staging_gender WHERE id = rg.id);


-- ------------ Accommodation ------------------------------------------------------------------------
UPDATE reporting.accommodation ra
  JOIN staging_accommodation sa ON sa.id = ra.id
SET
  ra.code = sa.code;

INSERT INTO reporting.accommodation ( id, code)
  SELECT
    sa.id,
    sa.code
  FROM staging_accommodation sa
    LEFT JOIN reporting.accommodation ra ON ra.id = sa.id
  WHERE ra.id IS NULL;

DELETE ra FROM reporting.accommodation ra
WHERE NOT EXISTS(SELECT id FROM staging_accommodation WHERE id = ra.id);


-- ------------ Claim ------------------------------------------------------------------------
UPDATE reporting.claim rc
  JOIN staging_claim sc ON sc.id = rc.id
SET
  rc.code = sc.code,
  rc.subject_id = sc.subject_id,
  rc.name = sc.name,
  rc.description = sc.description;

INSERT INTO reporting.claim ( id, subject_id, code, name, description)
  SELECT
    sc.id,
    sc.subject_id,
    sc.code,
    sc.name,
    sc.description
  FROM staging_claim sc
    LEFT JOIN reporting.claim rc ON rc.id = sc.id
  WHERE rc.id IS NULL;

DELETE rc FROM reporting.claim rc
WHERE NOT EXISTS(SELECT id FROM staging_claim WHERE id = rc.id);


-- ------------ Subject Claim Score --------------------------------------------------------------------
UPDATE reporting.subject_claim_score rc
  JOIN staging_subject_claim_score sc ON sc.id = rc.id
SET
  rc.subject_id = sc.subject_id,
  rc.asmt_type_id = sc.asmt_type_id,
  rc.code = sc.code,
  rc.name = sc.name;

INSERT INTO reporting.subject_claim_score ( id, subject_id, asmt_type_id, code, name)
  SELECT
    sc.id,
    sc.subject_id,
    sc.asmt_type_id,
    sc.code,
    sc.name
  FROM staging_subject_claim_score sc
    LEFT JOIN reporting.subject_claim_score rc ON rc.id = sc.id
  WHERE rc.id IS NULL;

DELETE rc FROM reporting.subject_claim_score rc
WHERE NOT EXISTS(SELECT id FROM staging_subject_claim_score WHERE id = rc.id);


-- ------------ Target ---------------------------------------------------------------------------
UPDATE reporting.target rt
  JOIN staging_target st ON st.id = rt.id
SET
  rt.claim_id = st.claim_id,
  rt.code = st.code,
  rt.description = st.description;

INSERT INTO reporting.target ( id, claim_id, code, description)
  SELECT
    st.id,
    st.claim_id,
    st.code,
    st.description
  FROM staging_target st
    LEFT JOIN reporting.target rt ON rt.id = st.id
  WHERE rt.id IS NULL;

DELETE rt FROM reporting.target rt
WHERE NOT EXISTS(SELECT id FROM staging_target WHERE id = rt.id);


-- ------------ Depth of knowledge ---------------------------------------------------------------------------
UPDATE reporting.depth_of_knowledge rdok
  JOIN staging_depth_of_knowledge sdok ON sdok.id = rdok.id
SET
  rdok.level = sdok.level,
  rdok.subject_id = sdok.subject_id,
  rdok.reference = sdok.reference,
  rdok.description = sdok.description;

INSERT INTO reporting.depth_of_knowledge ( id, level, subject_id, description, reference)
  SELECT
    sdok.id,
    sdok.level,
    sdok.subject_id,
    sdok.description,
    sdok.reference
  FROM staging_depth_of_knowledge sdok
    LEFT JOIN reporting.depth_of_knowledge rdok ON rdok.id = sdok.id
  WHERE rdok.id IS NULL;

DELETE rdok FROM reporting.depth_of_knowledge rdok
WHERE NOT EXISTS(SELECT id FROM staging_depth_of_knowledge WHERE id = rdok.id);


-- ------------ Math Practice ---------------------------------------------------------------------------
UPDATE reporting.math_practice rmp
  JOIN staging_math_practice smp ON smp.practice = rmp.practice
SET
  rmp.description = smp.description;

INSERT INTO reporting.math_practice ( practice, description)
  SELECT
    smp.practice,
    smp.description
  FROM staging_math_practice smp
    LEFT JOIN reporting.math_practice rmp ON rmp.practice = smp.practice
  WHERE rmp.practice IS NULL;

DELETE rmp FROM reporting.math_practice rmp
WHERE NOT EXISTS(SELECT practice FROM staging_math_practice WHERE practice = rmp.practice);


-- ------------ Item Trait Score ---------------------------------------------------------------------------
UPDATE reporting.item_trait_score rit
  JOIN staging_item_trait_score sit ON sit.id = rit.id
SET
  rit.dimension = sit.dimension;

INSERT INTO reporting.item_trait_score ( id, dimension)
  SELECT
    sit.id,
    sit.dimension
  FROM staging_item_trait_score sit
    LEFT JOIN reporting.item_trait_score rit ON rit.id = sit.id
  WHERE rit.id IS NULL;

DELETE rit FROM reporting.item_trait_score rit
WHERE NOT EXISTS(SELECT id FROM staging_item_trait_score WHERE id = rit.id);


-- ------------ Item Difficulty Cuts ---------------------------------------------------------------------------
UPDATE reporting.item_difficulty_cuts ridc
  JOIN staging_item_difficulty_cuts sidc ON sidc.id = ridc.id
SET
  ridc.asmt_type_id = sidc.asmt_type_id,
  ridc.subject_id = sidc.subject_id,
  ridc.grade_id = sidc.grade_id,
  ridc.moderate_low_end = sidc.moderate_low_end,
  ridc.difficult_low_end = sidc.difficult_low_end;

INSERT INTO reporting.item_difficulty_cuts (id, asmt_type_id, subject_id, grade_id, moderate_low_end, difficult_low_end)
  SELECT
    sidc.id,
    sidc.asmt_type_id,
    sidc.subject_id,
    sidc.grade_id,
    sidc.moderate_low_end,
    sidc.difficult_low_end
  FROM staging_item_difficulty_cuts sidc
    LEFT JOIN reporting.item_difficulty_cuts ridc ON ridc.id = sidc.id
  WHERE ridc.id IS NULL;

DELETE ridc FROM reporting.item_difficulty_cuts ridc
WHERE NOT EXISTS(SELECT id FROM staging_item_difficulty_cuts WHERE id = ridc.id);

-- -----------------------------------------------------------------------------------------
-- handle delete first
-- -----------------------------------------------------------------------------------------

-- School  ---------------------------------------------------------------------------------
-- student groups and exams depend on the school.
-- Assume that all the dependent deletes were processed first
-- TODO: how to handle errors in this case?
DELETE FROM reporting.school WHERE id IN (SELECT id FROM staging_school WHERE deleted = 1);

-- remove districts if it is not associated with a school
DELETE FROM reporting.district
WHERE id in (SELECT district_id from staging_school WHERE deleted = 1)
      AND NOT EXISTS(SELECT id from reporting.school WHERE district_id = id);

-- Student  ---------------------------------------------------------------------------------
-- student groups and exams depend on the school.
-- Assume that all the dependent deletes were processed first
-- TODO: how to handle errors in this case?
DELETE FROM reporting.student_ethnicity WHERE student_id IN (SELECT id FROM staging_student WHERE deleted = 1);
DELETE FROM reporting.student WHERE id in (SELECT id FROM staging_student WHERE deleted = 1);

-- Assessment ------------------------------------------------------------------------------
-- exam depend on the asmt
-- Assume that all the dependent deletes were processed first
DELETE FROM reporting.asmt_score WHERE asmt_id IN (SELECT id FROM staging_asmt WHERE deleted = 1);
DELETE FROM reporting.item WHERE asmt_id IN (SELECT id FROM staging_asmt WHERE deleted = 1);
DELETE FROM reporting.asmt WHERE id IN (SELECT id FROM staging_asmt WHERE deleted = 1);

-- -----------------------------------------------------------------------------------------
-- Update/insert
-- Note that updates comes before insert to avoid updating newly inserted records
-- -----------------------------------------------------------------------------------------

-- School  ---------------------------------------------------------------------------------
-- District first. This covers a use case when a school gets re-assigned to a new district
-- -----------------------------------------------------------------------------------------
UPDATE reporting.district d
  JOIN staging_district sd ON sd.id = d.id
SET d.name = sd.name;

INSERT INTO reporting.district(id, natural_id,name)
  SELECT
    sd.id,
    sd.natural_id,
    sd.name
  FROM staging_district sd
    LEFT JOIN reporting.district rd ON rd.id = sd.id
  WHERE rd.id IS NULL;

UPDATE reporting.school rs
  JOIN staging_school ss ON ss.id = rs.id
SET rs.name = ss.name,
  rs.district_id = ss.district_id,
  rs.import_id = ss.import_id
WHERE ss.deleted = 0;

INSERT INTO reporting.school (id, natural_id, name, district_id, import_id)
  SELECT
    ss.id,
    ss.natural_id,
    ss.name,
    ss.district_id,
    ss.import_id
  FROM staging_school ss
    LEFT JOIN reporting.school rs ON rs.id = ss.id
  WHERE rs.id IS NULL and ss.deleted = 0;

-- Student  ---------------------------------------------------------------------------------
-- Process students update/inserts first, and then all the ethnicity at once

-- TODO: do we need to wrap the below into a transaction? does it really matter?
UPDATE reporting.student rs
  JOIN staging_student ss ON ss.id = rs.id
SET
  rs.last_or_surname = ss.last_or_surname,
  rs.first_name = ss.first_name,
  rs.middle_name = ss.middle_name,
  rs.gender_id = ss.gender_id,
  rs.first_entry_into_us_school_at = ss.first_entry_into_us_school_at,
  rs.lep_entry_at = ss.lep_entry_at,
  rs.lep_exit_at = ss.lep_exit_at,
  rs.birthday = ss.birthday,
  rs.import_id = ss.import_id
WHERE ss.deleted = 0;

INSERT INTO reporting.student (id, ssid, last_or_surname, first_name, middle_name, gender_id, first_entry_into_us_school_at,
                               lep_entry_at, lep_exit_at, birthday, import_id)
  SELECT
    ss.id,
    ss.ssid,
    ss.last_or_surname,
    ss.first_name,
    ss.middle_name,
    ss.gender_id,
    ss.first_entry_into_us_school_at,
    ss.lep_entry_at,
    ss.lep_exit_at,
    ss.birthday,
    ss.import_id
  FROM staging_student ss
    LEFT JOIN reporting.student rs ON rs.id = ss.id
  WHERE rs.id IS NULL and ss.deleted = 0;

DELETE FROM reporting.student_ethnicity WHERE student_id in (SELECT id FROM staging_student);
INSERT INTO reporting.student_ethnicity( id, student_id, ethnicity_id)
  SELECT id, student_id, ethnicity_id from staging_student_ethnicity;

-- Assessment ------------------------------------------------------------------------------
UPDATE reporting.asmt ra
  JOIN staging_asmt sa ON sa.id = ra.id
SET
  ra.grade_id    = sa.grade_id,
  ra.type_id     = sa.type_id,
  ra.subject_id  = sa.subject_id,
  ra.school_year = sa.school_year,
  ra.name        = sa.name,
  ra.label       = sa.label,
  ra.version     = sa.version,
  ra.import_id   = sa.import_id
WHERE sa.deleted = 0;

INSERT INTO reporting.asmt (id, natural_id, grade_id, type_id, subject_id, school_year, name,
                            label, version, import_id)
  SELECT
    sa.id,
    sa.natural_id,
    sa.grade_id,
    sa.type_id,
    sa.subject_id,
    sa.school_year,
    sa.name,
    sa.label,
    sa.version,
    sa.import_id
  FROM staging_asmt sa
    LEFT JOIN reporting.asmt ra ON ra.id = sa.id
  WHERE ra.id IS NULL and sa.deleted = 0;

-- Dependent tables' changes are considered 'updates' to the asmt
-- We need to processes them independently
-- Note that dependent tables do not have any 'root' deletes
-- Deleted to the depended tables are considered 'root' updates.

UPDATE reporting.asmt_score ras
  JOIN staging_asmt_score sas ON ras.asmt_id = sas.asmt_id
SET
  ras.cut_point_1 = sas.cut_point_1,
  ras.cut_point_2 = sas.cut_point_2,
  ras.cut_point_3 = sas.cut_point_3,
  ras.min_score   = sas.min_score,
  ras.max_score   = sas.max_score;

INSERT INTO reporting.asmt_score ( asmt_id, cut_point_1, cut_point_2, cut_point_3, min_score, max_score)
  SELECT
    sas.asmt_id,
    sas.cut_point_1,
    sas.cut_point_2,
    sas.cut_point_3,
    sas.min_score,
    sas.max_score
  FROM staging_asmt_score sas
    LEFT JOIN reporting.asmt_score ras ON ras.asmt_id = sas.asmt_id
  WHERE ras.asmt_id IS NULL;

DELETE rs FROM reporting.asmt_score rs
WHERE rs.asmt_id in (select asmt_id from staging_asmt where deleted = 0)
      AND NOT EXISTS(SELECT asmt_id FROM staging_asmt_score WHERE asmt_id = rs.asmt_id);

UPDATE reporting.item ri
  JOIN staging_item si ON ri.asmt_id = si.asmt_id
SET
  ri.claim_id      = si.claim_id,
  ri.target_id     = si.target_id,
  ri.asmt_id       = si.asmt_id,
  ri.math_practice = si.math_practice,
  ri.allow_calc    = si.allow_calc,
  ri.dok_id        = si.dok_id,
  ri.difficulty    = si.difficulty,
  ri.max_points    = si.max_points;

INSERT INTO reporting.item ( id, claim_id, target_id, natural_id, asmt_id, math_practice, allow_calc, dok_id,
                             difficulty, max_points)
  SELECT
    si.id,
    si.claim_id,
    si.target_id,
    si.natural_id,
    si.asmt_id,
    si.math_practice,
    si.allow_calc,
    si.dok_id,
    si.difficulty,
    si.max_points
  FROM staging_item si
    LEFT JOIN reporting.item ri ON ri.id = si.id
  WHERE ri.id IS NULL;

DELETE ri FROM reporting.item ri
WHERE ri.asmt_id in (select id from staging_asmt where deleted = 0)
      AND  NOT EXISTS(SELECT id FROM staging_item WHERE id = ri.id);