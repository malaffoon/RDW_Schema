-- Add the ability to enable and disable audit triggers
-- 1: create table to hold a trigger on/off switch
-- 2: sample turn on and off
-- 2: modify audit triggers to respect the on/off switch

USE ${schemaName};

/*
 Create the table to hold the on/off switch
*/
CREATE TABLE audit_trigger_switch (
  id TINYINT NOT NULL PRIMARY KEY,
  switch TINYINT NOT NULL,
  updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
);

/*
 Insert the single switch record in the 'on' position.
 Disable audit triggers with: UPDATE audit_trigger_switch ats SET ats.switch = 0 WHERE ats.id = 1;
 Enable audit triggers with:  UPDATE audit_trigger_switch ats SET ats.switch = 1 WHERE ats.id = 1;
*/
INSERT INTO audit_trigger_switch (id, switch) VALUES (1, 1);

/*
  exam triggers
*/

-- UPDATE
DROP TRIGGER trg__exam__update;

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
      OLD.prim_disability_type
    );

-- DELETE
DROP TRIGGER trg__exam__delete;

CREATE TRIGGER trg__exam__delete
BEFORE DELETE ON exam
FOR EACH ROW
  INSERT INTO audit_exam (action, database_user, exam_id, type_id, school_year, asmt_id, asmt_version,
                          opportunity, oppId, completeness_id, administration_condition_id, session_id, scale_score,
                          scale_score_std_err, performance_level, completed_at, import_id, update_import_id, deleted,
                          created, updated, grade_id, student_id, school_id, iep, lep, section504,
                          economic_disadvantage, migrant_status, eng_prof_lvl, t3_program_type, language_code,
                          prim_disability_type)
  VALUES
    (
      'delete',
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
      OLD.prim_disability_type
    );

/*
  exam_claim_score audit triggers
*/

-- UPDATE
DROP TRIGGER trg__exam_claim_score__update;

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
      OLD.category
    );

-- DELETE
DROP TRIGGER trg__exam_claim_score__delete;

CREATE TRIGGER trg__exam_claim_score__delete
BEFORE DELETE ON exam_claim_score
FOR EACH ROW
  INSERT INTO audit_exam_claim_score (
    action, database_user, exam_claim_score_id, exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category
  )
  VALUES
    (
      'delete',
      USER(),
      OLD.id,
      OLD.exam_id,
      OLD.subject_claim_score_id,
      OLD.scale_score,
      OLD.scale_score_std_err,
      OLD.category
    );

/*
  exam_available_accommodation audit triggers
*/

-- UPDATE
DROP TRIGGER trg__exam_available_accommodation__update;

CREATE TRIGGER trg__exam_available_accommodation__update
BEFORE UPDATE ON exam_available_accommodation
FOR EACH ROW
  INSERT INTO audit_exam_available_accommodation (
    action, database_user, exam_id, accommodation_id
  )
  VALUES
    (
      'update',
      USER(),
      OLD.exam_id,
      OLD.accommodation_id
    );

-- DELETE
DROP TRIGGER trg__exam_available_accommodation__delete;

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
  exam_item audit triggers
*/

-- UPDATE
DROP TRIGGER trg__exam_item__update;

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

-- DELETE
DROP TRIGGER trg__exam_item__delete;

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



