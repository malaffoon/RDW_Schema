use staging;
-- ----------------------------------------------------------------------
-- School / District migration
-- ----------------------------------------------------------------------
-- TODO: this is a temp hack/simulation that I needed to test
TRUNCATE TABLE reporting.migrate;
-- In the real life this will be done at the beginning of the migration
INSERT INTO reporting.migrate (id, status, first_import_id, last_import_id)
VALUES (11, 10, 100, 1100);

-- ----------------------------------------------------------------------
-- clean up
-- ----------------------------------------------------------------------
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