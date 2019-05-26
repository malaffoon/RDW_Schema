-- Consolidated v1.2.0 -> v1.2.1 flyway script.
--
-- This script should be run against v1.2.0 installations where the schema_version table looks like:
-- +----------------+---------+------------------------------+--------+------------------------------+-------------+---------+
-- | installed_rank | version | description                  | type   | script                       | checksum    | success |
-- +----------------+---------+------------------------------+--------+------------------------------+-------------+---------+
-- |              1 | NULL    | << Flyway Schema Creation >> | SCHEMA | `warehouse`                  |        NULL |       1 |
-- |              2 | 1.0.0.0 | ddl                          | SQL    | V1_0_0_0__ddl.sql            |   751759817 |       1 |
-- |              3 | 1.0.0.1 | dml                          | SQL    | V1_0_0_1__dml.sql            |  1955603172 |       1 |
-- |              4 | 1.1.0.0 | update                       | SQL    | V1_1_0_0__update.sql         |   518740504 |       1 |
-- |              5 | 1.1.0.1 | audit                        | SQL    | V1_1_0_1__audit.sql          | -1236730527 |       1 |
-- |              6 | 1.1.1.0 | student upsert               | SQL    | V1_1_1_0__student_upsert.sql |  -223870699 |       1 |
-- |              7 | 1.2.0.0 | update                       | SQL    | V1_2_0_0__update.sql         |  -680448587 |       1 |
-- +----------------+---------+------------------------------+--------+------------------------------+-------------+---------+
--
-- This is a non-trivial script that modifies many tables in the system. It should be run with
-- auto-commit enabled. It will take a while to run ... the applications must be halted while
-- this is being applied.
--
-- When first created, RDW_Schema was on build #389 and this incorporated:
--   V1_2_1_0__configurable_subjects.sql
--   V1_2_1_1__configurable_subject_tighten_up.sql
--   V1_2_1_2__asmt_cut_points.sql
--   V1_2_1_3__relax_uniqueness.sql
--   V1_2_1_4__config_subject_cleanup.sql

use ${schemaName};

-- Drop foreign keys to allow for modifying the subject id column
ALTER TABLE asmt
  DROP FOREIGN KEY fk__asmt__subject;
ALTER TABLE claim
  DROP FOREIGN KEY fk__claim__subject,
  DROP INDEX idx__claim__subject;
ALTER TABLE common_core_standard
  DROP FOREIGN KEY fk__common_core_standard__subject,
  DROP INDEX idx__common_core_standard__subject;
ALTER TABLE depth_of_knowledge
  DROP FOREIGN KEY fk__depth_of_knowledge__subject,
  DROP INDEX idx__depth_of_knowledge__subject;
ALTER TABLE item_difficulty_cuts
  DROP FOREIGN KEY fk__item_difficulty_cuts__subject,
  DROP INDEX idx__item_difficulty_cuts__subject;
ALTER TABLE student_group
  DROP FOREIGN KEY fk__student_group__subject;
ALTER TABLE subject_claim_score
  DROP FOREIGN KEY fk__subject_claim_score__subject,
  DROP INDEX idx__subject_claim_score__subject;
ALTER TABLE subject_asmt_type
  DROP FOREIGN KEY fk__subject_asmt_type__subject;
ALTER TABLE subject_translation
  DROP FOREIGN KEY fk__subject_translation__subject;
ALTER TABLE item
  DROP FOREIGN KEY fk__item__dok;

ALTER TABLE depth_of_knowledge MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;
ALTER TABLE item_difficulty_cuts MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;
ALTER TABLE subject_claim_score MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;
ALTER TABLE subject MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;

ALTER TABLE asmt
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE claim
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  DROP COLUMN name,
  DROP COLUMN description;
ALTER TABLE common_core_standard
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  DROP COLUMN description;
ALTER TABLE asmt
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE depth_of_knowledge
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  DROP COLUMN description;
ALTER TABLE item_difficulty_cuts
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE student_group
  MODIFY COLUMN subject_id SMALLINT NULL;
ALTER TABLE subject_claim_score
  MODIFY COLUMN subject_id SMALLINT NOT NULL,
  ADD COLUMN data_order TINYINT,
  DROP COLUMN name;
ALTER TABLE subject_asmt_type
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE subject_translation
  MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE item
  MODIFY COLUMN dok_id SMALLINT NOT NULL;

-- Replace foreign keys after modifying the subject id column
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
ALTER TABLE item_difficulty_cuts
  ADD UNIQUE INDEX idx__tem_difficulty_cuts__subject_grade_diff(subject_id, grade_id),
  ADD CONSTRAINT fk__item_difficulty_cuts__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE student_group ADD CONSTRAINT fk__student_group__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_claim_score
  ADD UNIQUE INDEX idx__subject_claim_score__subject_asmt_code(subject_id, asmt_type_id, code),
  ADD CONSTRAINT fk__subject_claim_score__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_asmt_type
  ADD CONSTRAINT fk__subject_asmt_type__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_translation
  ADD CONSTRAINT fk__subject_translation__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE item
  ADD CONSTRAINT fk__item__dok FOREIGN KEY (dok_id) REFERENCES depth_of_knowledge(id);

ALTER TABLE target
  DROP COLUMN code,
  DROP COLUMN description,
  MODIFY COLUMN natural_id varchar(20) not null,
  DROP FOREIGN KEY fk__target__claim,
  DROP INDEX idx__target__claim,
  ADD UNIQUE INDEX idx__target__claim_natural_id(claim_id, natural_id);
ALTER TABLE target ADD CONSTRAINT fk__target__claim FOREIGN KEY (claim_id) REFERENCES claim(id);

ALTER TABLE asmt_score
  MODIFY COLUMN cut_point_2 float,
  ADD COLUMN cut_point_4 float,
  ADD COLUMN cut_point_5 float;

ALTER TABLE asmt_type
  DROP COLUMN name;

UPDATE subject_claim_score SET data_order = 1 WHERE code = '1' AND subject_id = 1;
UPDATE subject_claim_score SET data_order = 2 WHERE code = 'SOCK_2' AND subject_id = 1;
UPDATE subject_claim_score SET data_order = 3 WHERE code = '3' AND subject_id = 1;
UPDATE subject_claim_score SET data_order = 1 WHERE code = 'SOCK_R' AND subject_id = 2;
UPDATE subject_claim_score SET data_order = 2 WHERE code = 'SOCK_LS' AND subject_id = 2;
UPDATE subject_claim_score SET data_order = 3 WHERE code = '2-W' AND subject_id = 2;
UPDATE subject_claim_score SET data_order = 4 WHERE code = '4-CR' AND subject_id = 2;

-- Create SUBJECT import content and trigger re-import to synch-up the data and import ids
INSERT INTO import_content (id, name) VALUES (8, 'SUBJECT');

INSERT INTO import (status, content, contentType, digest) VALUES (0, 8, 'config subject support', 'config subject support v1.2.1');
SELECT LAST_INSERT_ID() INTO @import_id;
UPDATE subject SET import_id = @import_id, update_import_id = @import_id;

ALTER TABLE subject
  MODIFY COLUMN import_id BIGINT NOT NULL,
  MODIFY COLUMN update_import_id BIGINT NOT NULL;

UPDATE import SET status = 1 where id = @import_id;



