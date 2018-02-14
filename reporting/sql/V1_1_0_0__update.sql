-- Consolidated v1.0 -> v1.1.0 flyway script.
--
-- This script should be run against v1.0.x installations where the schema_version table looks like:
-- +----------------+---------+------------------------------+--------+-------------------+-------------+---------+
-- | installed_rank | version | description                  | type   | script            | checksum    | success |
-- +----------------+---------+------------------------------+--------+-------------------+-------------+---------+
-- |              1 | NULL    | << Flyway Schema Creation >> | SCHEMA | `warehouse`       |        NULL |       1 |
-- |              2 | 1.0.0.0 | ddl                          | SQL    | V1_0_0_0__ddl.sql |   986463590 |       1 |
-- |              3 | 1.0.0.1 | dml                          | SQL    | V1_0_0_1__dml.sql | -1123132459 |       1 |
-- +----------------+---------+------------------------------+--------+-------------------+-------------+---------+
--
-- When first created, RDW_Schema was on build #273 and this incorporated:
--   V1_0_0_2__add_index_to_import.sql
--   V1_0_2_0__remove_wer_warning.sql   <-- not incorporated because it was deployed manually
--   V1_1_0_1__add_user_report_chunk_tracking.sql
--   ...
--   V1_1_0_16__migrate_embargo.sql
--
-- A second merge happened when RDW_Schema was on build 316 and incorporated:
--   V1_1_0_1__percentile.sql
--   ...
--   V1_1_0_5__migrate_user_report_values.sql
-- It also included some changes that would've been in V1_1_0_6__claim_names.sql

USE ${schemaName};

ALTER TABLE migrate
  ADD INDEX idx__migrate_status_created (status, created),
  MODIFY COLUMN size int,
  ADD COLUMN migrate_embargo tinyint;

CREATE TABLE user_report_metadata (
  report_id BIGINT NOT NULL,
  name VARCHAR(50) NOT NULL,
  value VARCHAR(255) NOT NULL,
  PRIMARY KEY (report_id, name),
  CONSTRAINT fk__user_report__report_id FOREIGN KEY (report_id) REFERENCES user_report (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS staging_district_group (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  external_id varchar(40),
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_school_group (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  external_id varchar(40),
  migrate_id bigint NOT NULL
);

ALTER TABLE staging_district
  ADD COLUMN external_id varchar(40);

ALTER TABLE staging_school
  ADD COLUMN district_group_id int,
  ADD COLUMN school_group_id int,
  ADD COLUMN external_id varchar(40),
  CHANGE import_id update_import_id BIGINT NOT NULL;


CREATE TABLE IF NOT EXISTS district_group (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  external_id varchar(40),
  UNIQUE INDEX idx__district_group__natural_id (natural_id)
);

CREATE TABLE IF NOT EXISTS school_group (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  external_id varchar(40),
  UNIQUE INDEX idx__school_group__natural_id (natural_id)
);

ALTER TABLE district
  ADD COLUMN external_id varchar(40);

ALTER TABLE school
  ADD COLUMN district_group_id int,
  ADD COLUMN school_group_id int,
  ADD COLUMN external_id varchar(40),
  CHANGE import_id update_import_id BIGINT NOT NULL,
  ADD embargo_enabled tinyint NOT NULL DEFAULT 0,
  ADD INDEX idx__school__district_group (district_group_id),
  ADD INDEX idx__school__school_group (school_group_id),
  ADD CONSTRAINT fk__school__district_group FOREIGN KEY (district_group_id) REFERENCES district_group(id),
  ADD CONSTRAINT fk__school__school_group FOREIGN KEY (school_group_id) REFERENCES school_group(id);

CREATE TABLE IF NOT EXISTS staging_district_embargo (
  district_id int NOT NULL,
  individual tinyint,
  aggregate tinyint,
  migrate_id bigint NOT NULL
);


ALTER TABLE exam
  MODIFY COLUMN completed_at TIMESTAMP(6) NOT NULL,
  MODIFY COLUMN t3_program_type varchar(30),
  CHANGE import_id update_import_id BIGINT NOT NULL;

ALTER TABLE staging_exam
  ADD COLUMN grade_id tinyint NOT NULL,
  ADD COLUMN student_id int NOT NULL,
  ADD COLUMN school_id int NOT NULL,
  ADD COLUMN iep tinyint NOT NULL,
  ADD COLUMN lep tinyint NOT NULL,
  ADD COLUMN section504 tinyint,
  ADD COLUMN economic_disadvantage tinyint NOT NULL,
  ADD COLUMN migrant_status tinyint,
  ADD COLUMN eng_prof_lvl varchar(20),
  ADD COLUMN t3_program_type varchar(30),
  ADD COLUMN language_code varchar(3),
  ADD COLUMN prim_disability_type varchar(3),
  CHANGE import_id update_import_id BIGINT NOT NULL,
  MODIFY COLUMN completed_at TIMESTAMP(6) NOT NULL,
  DROP COLUMN exam_student_id;

DROP TABLE staging_exam_student;


ALTER TABLE asmt
  CHANGE import_id update_import_id BIGINT NOT NULL,
  ADD INDEX idx__asmt__name (name);

ALTER TABLE student
  ADD COLUMN inferred_school_id int,
  CHANGE import_id update_import_id BIGINT NOT NULL,
  ADD INDEX idx__student__inferred_school (inferred_school_id),
  ADD CONSTRAINT fk__student__inferred_school_id FOREIGN KEY (inferred_school_id) REFERENCES school(id);

ALTER TABLE student_group
  CHANGE import_id update_import_id BIGINT NOT NULL;

ALTER TABLE staging_student
  ADD COLUMN inferred_school_id int,
  CHANGE import_id update_import_id BIGINT NOT NULL;

ALTER TABLE staging_student_group
  CHANGE import_id update_import_id BIGINT NOT NULL;

ALTER TABLE staging_asmt
  CHANGE import_id update_import_id BIGINT NOT NULL;


ALTER TABLE translation
  ADD PRIMARY KEY (namespace, label_code, language_code),
  DROP INDEX idx__translation__namespace_label_code_language_code;


ALTER TABLE item
  ADD COLUMN field_test tinyint,
  ADD COLUMN active tinyint,
  ADD COLUMN type varchar(40),
  ADD COLUMN performance_task_writing_type varchar(16),
  ADD COLUMN options_count tinyint,
  ADD COLUMN answer_key varchar(50);

ALTER TABLE staging_item
  ADD COLUMN field_test tinyint,
  ADD COLUMN active tinyint,
  ADD COLUMN type varchar(40),
  ADD COLUMN performance_task_writing_type varchar(16),
  ADD COLUMN options_count tinyint,
  ADD COLUMN answer_key varchar(50);


ALTER TABLE instructional_resource
  DROP PRIMARY KEY,
  CHANGE name asmt_name VARCHAR(250) NOT NULL,
  ADD COLUMN org_level VARCHAR(15) NOT NULL DEFAULT 'System',
  ADD COLUMN performance_level TINYINT DEFAULT 0,
  ADD COLUMN org_id INT,
  ADD UNIQUE INDEX idx__instructional_resource (asmt_name, org_level, performance_level, org_id);


-- percentile -----------------------------------------------------------------------------------

CREATE TABLE percentile (
  id INT NOT NULL PRIMARY KEY,
  asmt_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  count INT NOT NULL,
  mean FLOAT NOT NULL,
  standard_deviation FLOAT NULL,
  min_score FLOAT NOT NULL,
  max_score FLOAT NOT NULL,
  update_import_id BIGINT NOT NULL,
  updated TIMESTAMP(6) NOT NULL,
  migrate_id BIGINT NOT NULL,
  UNIQUE INDEX idx__percentile__asmt_start_date_end_date (asmt_id, start_date, end_date),
  CONSTRAINT fk__percentile__asmt FOREIGN KEY (asmt_id) REFERENCES asmt (id)
);

CREATE TABLE percentile_score (
  percentile_id INT NOT NULL,
  percentile_rank TINYINT NOT NULL,
  score float NOT NULL,
  min_inclusive FLOAT NOT NULL,
  max_exclusive FLOAT NOT NULL,
  PRIMARY KEY (percentile_id, percentile_rank),
  CONSTRAINT fk__percentile_score__percentile FOREIGN KEY (percentile_id) REFERENCES percentile (id)
);

CREATE TABLE staging_percentile (
  id INT NOT NULL PRIMARY KEY,
  asmt_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  count INT NOT NULL,
  mean FLOAT NOT NULL,
  standard_deviation FLOAT NULL,
  min_score FLOAT NOT NULL,
  max_score FLOAT NOT NULL,
  update_import_id BIGINT NOT NULL,
  updated TIMESTAMP(6) NOT NULL,
  migrate_id BIGINT NOT NULL,
  deleted TINYINT NOT NULL,
  UNIQUE INDEX idx__staging_percentile__asmt_start_date_end_date (asmt_id, start_date, end_date)
);

CREATE TABLE staging_percentile_score (
  percentile_id INT NOT NULL,
  percentile_rank TINYINT NOT NULL,
  score float NOT NULL,
  min_inclusive FLOAT NOT NULL,
  max_exclusive FLOAT NOT NULL,
  PRIMARY KEY (percentile_id, percentile_rank)
);


-- fix claim names (these aren't really used but let's make them correct anyway) ----------------
UPDATE claim SET name='Reading' WHERE code='1-IT';
UPDATE claim SET name='Reading' WHERE code='1-LT';
UPDATE claim SET name='Writing' WHERE code='2-W';
UPDATE claim SET name='Listening' WHERE code='3-L';
UPDATE claim SET name='Listening' WHERE code='3-S';
UPDATE claim SET name='Research and Inquiry' WHERE code='4-CR';

-- remove obsolete Known Issues text
REPLACE INTO translation (label_code, namespace, language_code, label) VALUES
  ('html.system-news', 'frontend', 'eng',
   '<h2 class="blue-dark h3 mb-md">Note</h2><div class="summary-reports-container mb-md"><p>Item level data and session IDs are not available for tests administered prior to the 2017-18 school year.</p></div>');

