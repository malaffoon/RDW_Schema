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
-- tudent groups and exams depend on the school.
-- Assume that all the dependent deletes were processed first
-- TODO: how to handle errors in this case?
DELETE FROM reporting.student_ethnicity WHERE student_id IN (SELECT id FROM staging_student WHERE deleted = 1);
DELETE FROM reporting.student WHERE id in (SELECT id FROM staging_student WHERE deleted = 1);

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
  rs.import_id = ss.import_id;

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