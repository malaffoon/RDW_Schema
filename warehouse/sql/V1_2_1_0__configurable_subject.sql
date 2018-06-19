use ${schemaName};

-- Drop foreign keys to allow for modifying the subject id column
ALTER TABLE asmt DROP FOREIGN KEY fk__asmt__subject;
ALTER TABLE claim DROP FOREIGN KEY fk__claim__subject;
ALTER TABLE common_core_standard DROP FOREIGN KEY fk__common_core_standard__subject;
ALTER TABLE depth_of_knowledge DROP FOREIGN KEY fk__depth_of_knowledge__subject;
ALTER TABLE item_difficulty_cuts DROP FOREIGN KEY fk__item_difficulty_cuts__subject;
ALTER TABLE student_group DROP FOREIGN KEY fk__student_group__subject;
ALTER TABLE subject_claim_score DROP FOREIGN KEY fk__subject_claim_score__subject;
ALTER TABLE subject_asmt_type DROP FOREIGN KEY fk__subject_asmt_type__subject;
ALTER TABLE subject_translation DROP FOREIGN KEY fk__subject_translation__subject;
ALTER TABLE item DROP FOREIGN KEY fk__item__dok;

ALTER TABLE depth_of_knowledge MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;
ALTER TABLE item_difficulty_cuts MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;
ALTER TABLE subject_claim_score MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;
ALTER TABLE subject MODIFY COLUMN id SMALLINT AUTO_INCREMENT NOT NULL;

ALTER TABLE asmt MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE claim MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE common_core_standard MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE asmt MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE depth_of_knowledge MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE item_difficulty_cuts MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE student_group MODIFY COLUMN subject_id SMALLINT NULL;
ALTER TABLE subject_claim_score MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE subject_asmt_type MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE subject_translation MODIFY COLUMN subject_id SMALLINT NOT NULL;
ALTER TABLE item MODIFY COLUMN dok_id SMALLINT NOT NULL;

-- Replace foreign keys after modifying the subject id column
ALTER TABLE asmt ADD CONSTRAINT fk__asmt__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE claim ADD CONSTRAINT fk__claim__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE common_core_standard ADD CONSTRAINT fk__common_core_standard__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE depth_of_knowledge ADD CONSTRAINT fk__depth_of_knowledge__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE item_difficulty_cuts ADD CONSTRAINT fk__item_difficulty_cuts__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE student_group ADD CONSTRAINT fk__student_group__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_claim_score ADD CONSTRAINT fk__subject_claim_score__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_asmt_type ADD CONSTRAINT fk__subject_asmt_type__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE subject_translation ADD CONSTRAINT fk__subject_translation__subject FOREIGN KEY (subject_id) REFERENCES subject(id);
ALTER TABLE item ADD CONSTRAINT fk__item__dok FOREIGN KEY (dok_id) REFERENCES depth_of_knowledge(id);
