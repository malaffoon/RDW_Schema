-- Consolidated v1.1 -> v1.2.0 flyway script.
--
-- This script should be run against v1.1 installations where the schema_version table looks like:
-- +----------------+---------+------------------------------+--------+----------------------+-------------+---------+
-- | installed_rank | version | description                  | type   | script               | checksum    | success |
-- +----------------+---------+------------------------------+--------+----------------------+-------------+---------+
-- |              1 | NULL    | << Flyway Schema Creation >> | SCHEMA | `reporting`          |        NULL |       1 |
-- |              2 | 1.0.0.0 | ddl                          | SQL    | V1_0_0_0__ddl.sql    |   986463590 |       1 |
-- |              3 | 1.0.0.1 | dml                          | SQL    | V1_0_0_1__dml.sql    | -1123132459 |       1 |
-- |              4 | 1.1.0.0 | update                       | SQL    | V1_1_0_0__update.sql | -1706757701 |       1 |
-- |              5 | 1.2.0.0 | update                       | SQL    | V1_2_0_0__update.sql |  1999355730 |       1 |
-- +----------------+---------+------------------------------+--------+----------------------+-------------+---------+
--
-- When first created, RDW_Schema was on build #371 and this incorporated:
--   V1_2_1_1__configurable_subject_tighten_up.sql
--   V1_2_1_2__asmt_cut_points.sql
--   V1_2_1_3__relax_uniqueness.sql
--   V1_2_1_4__relax_constraints.sql
--   V1_2_1_5__config_subject_cleanup.sql

USE ${schemaName};

-- Drop FK references on subject.id for modification
ALTER TABLE asmt
  ADD COLUMN claim5_score_code varchar(10),
  ADD COLUMN claim6_score_code varchar(10),
  MODIFY COLUMN cut_point_2 smallint,
  ADD COLUMN cut_point_4 smallint,
  ADD COLUMN cut_point_5 smallint,
  DROP FOREIGN KEY fk__asmt__subject,
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE staging_asmt MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE claim
  DROP FOREIGN KEY fk__claim__subject,
  DROP INDEX idx__claim__subject,
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  DROP COLUMN name,
  DROP COLUMN description;
ALTER TABLE staging_claim
  DROP COLUMN name,
  DROP COLUMN description,
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE common_core_standard
  DROP FOREIGN KEY fk__common_core_standard__subject,
  DROP INDEX idx__common_core_standard__subject,
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  DROP COLUMN description;
ALTER TABLE staging_common_core_standard
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  DROP COLUMN description;
ALTER TABLE depth_of_knowledge
  DROP FOREIGN KEY fk__depth_of_knowledge__subject,
  DROP INDEX idx__depth_of_knowledge__subject,
  DROP COLUMN description,
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE staging_depth_of_knowledge
  DROP COLUMN description,
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE student_group
  DROP FOREIGN KEY fk__student_group__subject,
  MODIFY COLUMN subject_id SMALLINT;
ALTER TABLE staging_student_group MODIFY COLUMN subject_id SMALLINT;
ALTER TABLE subject_claim_score
  DROP FOREIGN KEY fk__subject_claim_score__subject,
  DROP INDEX idx__subject_claim_score__subject,
  ADD COLUMN data_order TINYINT,
  DROP COLUMN name,
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE teacher_student_group
  DROP FOREIGN KEY fk__teacher_student_group__subject,
  MODIFY COLUMN subject_id SMALLINT;

-- Alter subject table to hold import references
ALTER TABLE subject
  MODIFY COLUMN id SMALLINT NOT NULL,
  ADD COLUMN updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  ADD COLUMN update_import_id BIGINT,
  ADD COLUMN migrate_id BIGINT;

-- Re-add FK references on subject.id
ALTER TABLE asmt
  ADD CONSTRAINT fk__asmt__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE claim
  ADD UNIQUE INDEX idx__claim__subject_code(subject_id, code),
  ADD CONSTRAINT fk__claim__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE common_core_standard
  ADD UNIQUE INDEX idx__common_core_standard__subject_natural_id(subject_id, natural_id),
  ADD CONSTRAINT fk__common_core_standard__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE depth_of_knowledge
  ADD UNIQUE INDEX idx__depth_of_knowledge__subject_level(subject_id, level),
  ADD CONSTRAINT fk__depth_of_knowledge__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE student_group
  ADD CONSTRAINT fk__student_group__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_claim_score
  ADD UNIQUE INDEX idx__subject_claim_score__subject_asmt_code(subject_id, asmt_type_id, code),
  ADD CONSTRAINT fk__subject_claim_score__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE teacher_student_group
  ADD CONSTRAINT fk__teacher_student_group__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

CREATE TABLE staging_subject (
  id SMALLINT NOT NULL,
  code VARCHAR(10) NOT NULL,
  updated TIMESTAMP NOT NULL,
  update_import_id BIGINT NOT NULL,
  migrate_id BIGINT NOT NULL,
  PRIMARY KEY (id)
);

ALTER TABLE asmt_score
  MODIFY COLUMN cut_point_2 smallint,
  ADD COLUMN cut_point_4 smallint,
  ADD COLUMN cut_point_5 smallint;

ALTER TABLE staging_asmt_score
  MODIFY COLUMN cut_point_2 smallint,
  ADD COLUMN cut_point_4 smallint,
  ADD COLUMN cut_point_5 smallint;

ALTER TABLE asmt_type
  DROP COLUMN name;


-- Create a subject display text table
CREATE TABLE subject_translation (
  subject_id SMALLINT NOT NULL,
  label_code VARCHAR(128) NOT NULL,
  label TEXT,
  PRIMARY KEY(subject_id, label_code),
  CONSTRAINT fk__subject_translation__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);
CREATE TABLE staging_subject_translation (
  subject_id SMALLINT NOT NULL,
  label_code VARCHAR(128) NOT NULL,
  label TEXT,
  PRIMARY KEY(subject_id, label_code)
);

-- Make code and description nullable for targets
ALTER TABLE target
  DROP COLUMN code,
  DROP COLUMN description,
  MODIFY COLUMN natural_id VARCHAR(20) NOT NULL,
  DROP FOREIGN KEY fk__target__claim,
  DROP INDEX idx__target__claim,
  ADD UNIQUE INDEX idx__target__claim_natural_id(claim_id, natural_id);
ALTER TABLE target ADD CONSTRAINT fk__target__claim FOREIGN KEY (claim_id) REFERENCES claim(id);

ALTER TABLE staging_target
  DROP COLUMN code,
  DROP COLUMN description,
  MODIFY COLUMN natural_id varchar(20) not null;

ALTER TABLE item
  DROP FOREIGN KEY fk__item__dok,
  DROP COLUMN target_code,
  DROP COLUMN dok_level_subject_id,
  MODIFY COLUMN dok_id SMALLINT;
ALTER TABLE staging_item MODIFY COLUMN dok_id SMALLINT;
ALTER TABLE depth_of_knowledge
  MODIFY COLUMN id SMALLINT NOT NULL;
ALTER TABLE item ADD CONSTRAINT fk__item__dok FOREIGN KEY (dok_id) REFERENCES depth_of_knowledge(id);
ALTER TABLE staging_depth_of_knowledge
  MODIFY COLUMN id SMALLINT NOT NULL;

ALTER TABLE staging_grade
  DROP COLUMN name;

-- Table for holding subject configurations in the context of an assessment type
CREATE TABLE subject_asmt_type (
  asmt_type_id TINYINT NOT NULL,
  subject_id SMALLINT NOT NULL,
  performance_level_count TINYINT NOT NULL,
  performance_level_standard_cutoff TINYINT,
  claim_score_performance_level_count TINYINT,
  PRIMARY KEY(asmt_type_id, subject_id),
  INDEX idx__subject_asmt_type__subject (subject_id),
  CONSTRAINT fk__subject_asmt_type__asmt_type FOREIGN KEY (asmt_type_id) REFERENCES asmt_type(id),
  CONSTRAINT fk__subject_asmt_type__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);
CREATE TABLE staging_subject_asmt_type (
  asmt_type_id TINYINT NOT NULL,
  subject_id SMALLINT NOT NULL,
  performance_level_count TINYINT NOT NULL,
  performance_level_standard_cutoff TINYINT,
  claim_score_performance_level_count TINYINT,
  PRIMARY KEY(asmt_type_id, subject_id)
);

ALTER TABLE exam
  ADD COLUMN claim5_scale_score smallint,
  ADD COLUMN claim5_scale_score_std_err float,
  ADD COLUMN claim5_category tinyint,
  ADD COLUMN claim6_scale_score smallint,
  ADD COLUMN claim6_scale_score_std_err float,
  ADD COLUMN claim6_category tinyint;

ALTER TABLE grade
  DROP COLUMN name;

-- Insert data for Math: 1, ELA: 2
-- ICA: 1, IAB: 2, SUM: 3
INSERT INTO subject_asmt_type (asmt_type_id, subject_id, performance_level_count, performance_level_standard_cutoff, claim_score_performance_level_count) VALUES
  (1, 1, 4, 3, 3),
  (2, 1, 3, null, null),
  (3, 1, 4, 3, 3),
  (1, 2, 4, 3, 3),
  (2, 2, 3, null, null),
  (3, 2, 4, 3, 3);

-- we can now use `subject_claim_score` table with the id and `display_order`
DROP TABLE exam_claim_score_mapping;

-- these are not used in reporting
DROP TABLE item_trait_score;
DROP TABLE staging_item_trait_score;

ALTER TABLE subject_claim_score
  ADD COLUMN display_order TINYINT,
  MODIFY COLUMN id SMALLINT NOT NULL;

CREATE TABLE staging_subject_claim_score (
  id SMALLINT NOT NULL,
  subject_id SMALLINT NOT NULL,
  asmt_type_id TINYINT NOT NULL,
  code varchar(10) NOT NULL,
  data_order TINYINT NOT NULL,
  display_order TINYINT NOT NULL,
  PRIMARY KEY (id)
);

-- load data for the existing scores
UPDATE subject_claim_score SET data_order = 1 WHERE code = '1' AND subject_id = 1;
UPDATE subject_claim_score SET data_order = 2 WHERE code = 'SOCK_2' AND subject_id = 1;
UPDATE subject_claim_score SET data_order = 3 WHERE code = '3' AND subject_id = 1;
UPDATE subject_claim_score SET data_order = 1 WHERE code = 'SOCK_R' AND subject_id = 2;
UPDATE subject_claim_score SET data_order = 2 WHERE code = 'SOCK_LS' AND subject_id = 2;
UPDATE subject_claim_score SET data_order = 3 WHERE code = '2-W' AND subject_id = 2;
UPDATE subject_claim_score SET data_order = 4 WHERE code = '4-CR' AND subject_id = 2;

UPDATE subject_claim_score SET display_order = 1 WHERE code = '1' AND subject_id = 1;
UPDATE subject_claim_score SET display_order = 2 WHERE code = 'SOCK_2' AND subject_id = 1;
UPDATE subject_claim_score SET display_order = 3 WHERE code = '3' AND subject_id = 1;
UPDATE subject_claim_score SET display_order = 1 WHERE code = 'SOCK_R' AND subject_id = 2;
UPDATE subject_claim_score SET display_order = 2 WHERE code = 'SOCK_LS' AND subject_id = 2;
UPDATE subject_claim_score SET display_order = 3 WHERE code = '2-W' AND subject_id = 2;
UPDATE subject_claim_score SET display_order = 4 WHERE code = '4-CR' AND subject_id = 2;

-- Apply constraints now that data is loaded
ALTER TABLE subject_claim_score
  MODIFY COLUMN data_order TINYINT NOT NULL,
  MODIFY COLUMN display_order TINYINT NOT NULL;


-- warehouse schema has a change that will force subject re-migration and will update `update_import_id`
UPDATE subject SET update_import_id = -1, migrate_id = -1;

ALTER TABLE subject
  MODIFY COLUMN update_import_id BIGINT NOT NULL,
  MODIFY COLUMN migrate_id BIGINT NOT NULL;
