use ${schemaName};

-- Add unique constraints.
-- To avoid redundant indexes, first dropped FK and Indexes that supports them, and re-created FK afterwards
ALTER TABLE depth_of_knowledge
    DROP FOREIGN KEY fk__depth_of_knowledge__subject,
    DROP INDEX idx__depth_of_knowledge__subject,
    ADD UNIQUE INDEX idx__depth_of_knowledge__subject_level(subject_id, level);
ALTER TABLE depth_of_knowledge ADD CONSTRAINT fk__depth_of_knowledge__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

ALTER TABLE item_difficulty_cuts
    DROP FOREIGN KEY fk__item_difficulty_cuts__subject,
    DROP INDEX idx__item_difficulty_cuts__subject,
    ADD UNIQUE INDEX idx__tem_difficulty_cuts__subject_grade_diff(subject_id, grade_id);
ALTER TABLE item_difficulty_cuts ADD CONSTRAINT fk__item_difficulty_cuts__subject FOREIGN KEY (subject_id) REFERENCES subject(id);

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

-- add a column to support claims pivoting during migrate into reporting
ALTER TABLE subject_claim_score
 ADD COLUMN data_order TINYINT;

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

-- TODO: IMPORTANT TO NOT FORGET once we have the ingest changes to support it
--ALTER TABLE subject_claim_score
-- MODIFY COLUMN data_order TINYINT NOT NULL;

-- TODO:clean up
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
