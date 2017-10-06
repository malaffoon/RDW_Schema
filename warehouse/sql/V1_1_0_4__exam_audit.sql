-- Create tables to hold audit for update and delete of exams
-- 1: create audit tables
-- 2: create triggers

USE ${schemaName};

/*
  Add created timestamp to child tables of parent being audited.
  Audit records are created for update and delete.
  Timestamp is required for exam updates that include creating a new child record.
  Child records do now have the import id.
*/

ALTER TABLE exam_claim_score
  ADD COLUMN created timestamp(6) default CURRENT_TIMESTAMP(6) not null;

ALTER TABLE exam_available_accommodation
  ADD COLUMN created timestamp(6) default CURRENT_TIMESTAMP(6) not null;

ALTER TABLE exam_item
  ADD COLUMN created timestamp(6) default CURRENT_TIMESTAMP(6) not null;

/*
  exam audit table and triggers
  exam can be updated
*/

CREATE TABLE IF NOT EXISTS audit_exam (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  exam_id BIGINT NOT NULL,
  type_id TINYINT NOT NULL,
  school_year SMALLINT(6) NOT NULL,
  asmt_id INT NOT NULL,
  asmt_version VARCHAR(30) NULL,
  opportunity INT NULL,
  oppId VARCHAR(60) NULL,
  completeness_id TINYINT NOT NULL,
  administration_condition_id TINYINT NOT NULL,
  session_id VARCHAR(128) NOT NULL,
  scale_score FLOAT NULL,
  scale_score_std_err FLOAT NULL,
  performance_level TINYINT NULL,
  completed_at TIMESTAMP NOT NULL,
  import_id BIGINT NOT NULL,
  update_import_id BIGINT NOT NULL,
  deleted TINYINT NOT NULL,
  created TIMESTAMP(6) NOT NULL,
  updated TIMESTAMP(6) NOT NULL,
  grade_id TINYINT NOT NULL,
  student_id INT NOT NULL,
  school_id INT NOT NULL,
  iep TINYINT NOT NULL,
  lep TINYINT NOT NULL,
  section504 TINYINT NULL,
  economic_disadvantage TINYINT NOT NULL,
  migrant_status TINYINT NULL,
  eng_prof_lvl VARCHAR(20) NULL,
  t3_program_type VARCHAR(20) NULL,
  language_code VARCHAR(3) NULL,
  prim_disability_type VARCHAR(3) NULL
);

CREATE TRIGGER trg__exam__update
BEFORE UPDATE ON exam
FOR EACH ROW
  INSERT INTO audit_exam (action, database_user, exam_id, type_id, school_year, asmt_id, asmt_version,
                          opportunity, oppId, completeness_id, administration_condition_id, session_id, scale_score,
                          scale_score_std_err, performance_level, completed_at, import_id, update_import_id, deleted,
                          created, updated, grade_id, student_id, school_id, iep, lep, section504,
                          economic_disadvantage, migrant_status, eng_prof_lvl, t3_program_type, language_code,
                          prim_disability_type)
  VALUES
    (
      'update',
      USER(),
      OLD.id,
      OLD.type_id,
      OLD.school_year,
      OLD.asmt_id,
      OLD.asmt_version,
      OLD.opportunity,
      OLD.oppId,
      OLD.completeness_id,
      OLD.administration_condition_id,
      OLD.session_id,
      OLD.scale_score,
      OLD.scale_score_std_err,
      OLD.performance_level,
      OLD.completed_at,
      OLD.import_id,
      OLD.update_import_id,
      OLD.deleted,
      OLD.created,
      OLD.updated,
      OLD.grade_id,
      OLD.student_id,
      OLD.school_id,
      OLD.iep,
      OLD.lep,
      OLD.section504,
      OLD.economic_disadvantage,
      OLD.migrant_status,
      OLD.eng_prof_lvl,
      OLD.t3_program_type,
      OLD.language_code,
      OLD.prim_disability_type);


/*
  exam_claim_score audit table and triggers
  exam_claim_score can be updated
*/

CREATE TABLE IF NOT EXISTS audit_exam_claim_score (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  exam_claim_score_id BIGINT NOT NULL,
  exam_id BIGINT NOT NULL,
  subject_claim_score_id SMALLINT(6) NOT NULL,
  scale_score FLOAT NULL,
  scale_score_std_err FLOAT NULL,
  category TINYINT NULL
);

CREATE TRIGGER trg__exam_claim_score__update
BEFORE UPDATE ON exam_claim_score
FOR EACH ROW
  INSERT INTO audit_exam_claim_score (
    action, database_user, exam_claim_score_id, exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category
  )
  VALUES
    (
      'update',
      USER(),
      OLD.id,
      OLD.exam_id,
      OLD.subject_claim_score_id,
      OLD.scale_score,
      OLD.scale_score_std_err,
      OLD.category);

/*
  exam_available_accommodation audit table and triggers
  exam_available_accommodation can be deleted
*/

CREATE TABLE IF NOT EXISTS audit_exam_available_accommodation (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  exam_id BIGINT NOT NULL,
  accommodation_id SMALLINT(6) NOT NULL
);

CREATE TRIGGER trg__exam_available_accommodation__delete
BEFORE DELETE ON exam_available_accommodation
FOR EACH ROW
  INSERT INTO audit_exam_available_accommodation (
    action, database_user, exam_id, accommodation_id
  )
  VALUES
    (
      'delete',
      USER(),
      OLD.exam_id,
      OLD.accommodation_id
    );

/*
  exam_item audit table and triggers
  exam_item can be updated and deleted
*/

CREATE TABLE IF NOT EXISTS audit_exam_item (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(8) NOT NULL,
  audited TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  database_user VARCHAR(255) NOT NULL,
  exam_item_id BIGINT NOT NULL,
  exam_id BIGINT NOT NULL,
  item_id INT NOT NULL,
  score FLOAT NOT NULL,
  score_status VARCHAR(50) NULL,
  position SMALLINT(6) NOT NULL,
  response TEXT NULL,
  trait_evidence_elaboration_score FLOAT NULL,
  trait_evidence_elaboration_score_status VARCHAR(50) NULL,
  trait_organization_purpose_score FLOAT NULL,
  trait_organization_purpose_score_status VARCHAR(50) NULL,
  trait_conventions_score FLOAT NULL,
  trait_conventions_score_status VARCHAR(50) NULL
);

CREATE TRIGGER trg__exam_item__update
BEFORE UPDATE ON exam_item
FOR EACH ROW
  INSERT INTO audit_exam_item (
    action, database_user, exam_item_id, exam_id, item_id, score,
    score_status, position, response, trait_evidence_elaboration_score,
    trait_evidence_elaboration_score_status, trait_organization_purpose_score,
    trait_organization_purpose_score_status, trait_conventions_score, trait_conventions_score_status
  )
  VALUES
    (
      'update',
      USER(),
      OLD.id,
      OLD.exam_id,
      OLD.item_id,
      OLD.score,
      OLD.score_status,
      OLD.position,
      OLD.response,
      OLD.trait_evidence_elaboration_score,
      OLD.trait_evidence_elaboration_score_status,
      OLD.trait_organization_purpose_score,
      OLD.trait_organization_purpose_score_status,
      OLD.trait_conventions_score,
      OLD.trait_conventions_score_status
    );

CREATE TRIGGER trg__exam_item__delete
BEFORE DELETE ON exam_item
FOR EACH ROW
  INSERT INTO audit_exam_item (
    action, database_user, exam_item_id, exam_id, item_id, score,
    score_status, position, response, trait_evidence_elaboration_score,
    trait_evidence_elaboration_score_status, trait_organization_purpose_score,
    trait_organization_purpose_score_status, trait_conventions_score, trait_conventions_score_status
  )
  VALUES
    (
      'delete',
      USER(),
      OLD.id,
      OLD.exam_id,
      OLD.item_id,
      OLD.score,
      OLD.score_status,
      OLD.position,
      OLD.response,
      OLD.trait_evidence_elaboration_score,
      OLD.trait_evidence_elaboration_score_status,
      OLD.trait_organization_purpose_score,
      OLD.trait_organization_purpose_score_status,
      OLD.trait_conventions_score,
      OLD.trait_conventions_score_status
    );


