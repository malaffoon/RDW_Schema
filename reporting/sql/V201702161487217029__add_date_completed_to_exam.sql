/**
** Misc. updates
**/

USE reporting;

ALTER TABLE iab_exam
  DROP FOREIGN KEY fk__iab_exam__claim,
  DROP COLUMN claim_id,
  DROP COLUMN claim_scale_score,
  DROP COLUMN claim_scale_score_std_err,
  DROP COLUMN claim_level,
  ADD COLUMN scale_score float,
  ADD COLUMN scale_score_std_err float,
  ADD COLUMN category tinyint,
  DROP COLUMN completeness,
  ADD COLUMN completeness_id tinyint NOT NULL,
  ADD CONSTRAINT fk__iab_exam_claim__completness FOREIGN KEY (completeness_id) REFERENCES completeness(id);

ALTER TABLE exam
  DROP COLUMN completeness,
  ADD COLUMN completeness_id tinyint NOT NULL,
  ADD CONSTRAINT fk__exam_claim__completness FOREIGN KEY (completeness_id) REFERENCES completeness(id);

ALTER TABLE exam_claim_score
  DROP COLUMN level,
  ADD COLUMN category tinyint;

ALTER TABLE exam_item
 DROP FOREIGN KEY fk__exam_item__item,
 DROP COLUMN item_id,
 ADD COLUMN item_key bigint NOT NULL,
 ADD COLUMN  bank_key varchar(40) NOT NULL;

ALTER TABLE iab_exam_item
 DROP FOREIGN KEY fk__iab_exam_item__item,
 DROP COLUMN item_id,
 ADD COLUMN item_key bigint NOT NULL,
 ADD COLUMN  bank_key varchar(40) NOT NULL;

CREATE TABLE IF NOT EXISTS item_trait_score (
  id tinyint NOT NULL PRIMARY KEY,
  dimension varchar(100) NOT NULL UNIQUE
 );

INSERT INTO item_trait_score (id, dimension) VALUES
  (1, 'Evidence/Elaboration'),
  (2, 'Organization/Purpose'),
  (3, 'Conventions');

CREATE TABLE IF NOT EXISTS iab_exam_item_trait_score (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  iab_exam_item_id bigint NOT NULL,
  item_trait_score_id tinyint NOT NULL,
  score float NOT NULL,
  score_status varchar(50),
  CONSTRAINT fk__iab_exam_item_trait_score__iab_exam_item FOREIGN KEY (iab_exam_item_id) REFERENCES iab_exam_item(id),
  CONSTRAINT fk__iab_exam_item_trait_score__item_trait_score FOREIGN KEY (item_trait_score_id) REFERENCES item_trait_score(id)
);

CREATE TABLE IF NOT EXISTS exam_item_trait_score (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  exam_item_id bigint NOT NULL,
  item_trait_score_id tinyint NOT NULL,
  score float NOT NULL,
  score_status varchar(50),
  CONSTRAINT fk__exam_item_trait_score__exam_item FOREIGN KEY (exam_item_id) REFERENCES exam_item(id),
  CONSTRAINT fk__exam_item_trait_score__item_trait_score FOREIGN KEY (item_trait_score_id) REFERENCES item_trait_score(id)
);