use ${schemaName};

-- Add unique constraints.
-- To avoid redundant indexes, first dropped FK and Indexes that supports them, and re-created FK afterwards
ALTER TABLE depth_of_knowledge
    DROP FOREIGN KEY fk__depth_of_knowledge__subject,
    DROP INDEX idx__depth_of_knowledge__subject,
    ADD UNIQUE INDEX idx__depth_of_knowledge__subject_level(subject_id, level);
ALTER TABLE depth_of_knowledge ADD CONSTRAINT fk__depth_of_knowledge__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

ALTER TABLE claim
    DROP FOREIGN KEY fk__claim__subject,
    ADD UNIQUE INDEX idx__claim__subject_code(subject_id, code);
ALTER TABLE claim ADD CONSTRAINT fk__claim__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

ALTER TABLE common_core_standard
    DROP FOREIGN KEY fk__common_core_standard__subject,
    DROP INDEX idx__common_core_standard__subject,
    ADD UNIQUE INDEX idx__common_core_standard__subject_natural_id(subject_id, natural_id);
ALTER TABLE common_core_standard ADD CONSTRAINT fk__common_core_standard__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

ALTER TABLE subject_claim_score
    DROP FOREIGN KEY fk__subject_claim_score__subject,
    DROP INDEX idx__subject_claim_score__subject,
    ADD UNIQUE INDEX idx__subject_claim_score__subject_asmt_code(subject_id, asmt_type_id, code);
ALTER TABLE subject_claim_score ADD CONSTRAINT fk__subject_claim_score__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

ALTER TABLE target
    DROP FOREIGN KEY fk__target__claim,
    DROP INDEX idx__target__claim,
    ADD UNIQUE INDEX idx__target__claim_natural_id(claim_id, natural_id);
ALTER TABLE target ADD CONSTRAINT fk__target__claim FOREIGN KEY (claim_id) REFERENCES claim(id);

-- we can now use `subject_claim_score` table with the id and `display_order`
DROP TABLE exam_claim_score_mapping;

-- there is not used in the reporting
DROP TABLE item_trait_score;
DROP TABLE staging_item_trait_score;

-- add up to the max supported claims
ALTER TABLE asmt
  ADD COLUMN claim5_score_code varchar(10),
  ADD COLUMN claim6_score_code varchar(10);

ALTER TABLE exam
  ADD COLUMN claim5_scale_score smallint,
  ADD COLUMN claim5_scale_score_std_err float,
  ADD COLUMN claim5_category tinyint,
  ADD COLUMN claim6_scale_score smallint,
  ADD COLUMN claim6_scale_score_std_err float,
  ADD COLUMN claim6_category tinyint;

-- warehouse schema has a change that will force subject re-migration and will update `update_import_id`
UPDATE subject SET update_import_id = -1, migrate_id = -1;

ALTER TABLE subject
    MODIFY COLUMN update_import_id BIGINT NOT NULL,
    MODIFY COLUMN migrate_id BIGINT NOT NULL;

-- TODO:
--ALTER TABLE depth_of_knowledge
--    DROP COLUMN description;
--ALTER TABLE claim
--    DROP COLUMN name,
--    DROP COLUMN description;
--ALTER TABLE common_core_standard
--    DROP COLUMN description;
--ALTER TABLE subject_claim_score
--    DROP COLUMN name;
--ALTER TABLE target
--    DROP COLUMN code,
--    DROP COLUMN description;
