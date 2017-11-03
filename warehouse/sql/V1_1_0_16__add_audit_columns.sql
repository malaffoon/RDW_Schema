-- Add missing columns to audit exam child tables
-- 1: add the created column that comes from the created timestamp on the exam_ child record
-- 2: re create the triggers
-- 3: this will coincide with integration tests updates on these tables that ensure all columns are audited.

USE ${schemaName};

-- Add created columns to audit tables.
-- Since auditing is not yet released these tables should have rows deleted.
-- This truncate should be removed when production release combined flyway is created.
TRUNCATE TABLE audit_exam_claim_score;
TRUNCATE TABLE audit_exam_available_accommodation;
TRUNCATE TABLE audit_exam_item;

ALTER TABLE audit_exam_claim_score
  ADD COLUMN created TIMESTAMP(6) NOT NULL;

ALTER TABLE audit_exam_available_accommodation
  ADD COLUMN created TIMESTAMP(6) NOT NULL;

ALTER TABLE audit_exam_item
  ADD COLUMN created TIMESTAMP(6) NOT NULL;

-- audit_exam_claim_score update trigger
DROP TRIGGER trg__exam_claim_score__update;

CREATE TRIGGER trg__exam_claim_score__update
BEFORE UPDATE ON exam_claim_score
FOR EACH ROW
  INSERT INTO audit_exam_claim_score (
    action, database_user, exam_claim_score_id, exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category,
    theta_score,
    theta_score_std_err,
    created
  )
    SELECT
      'update',
      USER(),
      OLD.id,
      OLD.exam_id,
      OLD.subject_claim_score_id,
      OLD.scale_score,
      OLD.scale_score_std_err,
      OLD.category,
      OLD.theta_score,
      OLD.theta_score_std_err,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

-- audit_exam_claim_score delete trigger
DROP TRIGGER trg__exam_claim_score__delete;

CREATE TRIGGER trg__exam_claim_score__delete
BEFORE DELETE ON exam_claim_score
FOR EACH ROW
  INSERT INTO audit_exam_claim_score (
    action, database_user, exam_claim_score_id, exam_id, subject_claim_score_id, scale_score, scale_score_std_err, category,
    theta_score,
    theta_score_std_err,
    created
  )
    SELECT
      'delete',
      USER(),
      OLD.id,
      OLD.exam_id,
      OLD.subject_claim_score_id,
      OLD.scale_score,
      OLD.scale_score_std_err,
      OLD.category,
      OLD.theta_score,
      OLD.theta_score_std_err,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

-- audit_exam_available_accommodation update trigger
DROP TRIGGER trg__exam_available_accommodation__update;

CREATE TRIGGER trg__exam_available_accommodation__update
BEFORE UPDATE ON exam_available_accommodation
FOR EACH ROW
  INSERT INTO audit_exam_available_accommodation (
    action, database_user, exam_id, accommodation_id, created
  )
    SELECT
      'update',
      USER(),
      OLD.exam_id,
      OLD.accommodation_id,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';


-- audit_exam_available_accommodation delete trigger
DROP TRIGGER trg__exam_available_accommodation__delete;

CREATE TRIGGER trg__exam_available_accommodation__delete
BEFORE DELETE ON exam_available_accommodation
FOR EACH ROW
  INSERT INTO audit_exam_available_accommodation (
    action, database_user, exam_id, accommodation_id, created
  )
    SELECT
      'delete',
      USER(),
      OLD.exam_id,
      OLD.accommodation_id,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

-- audit_exam_item update trigger
DROP TRIGGER trg__exam_item__update;

CREATE TRIGGER trg__exam_item__update
BEFORE UPDATE ON exam_item
FOR EACH ROW
  INSERT INTO audit_exam_item (
    action, database_user, exam_item_id, exam_id, item_id, score,
    score_status, position, response, trait_evidence_elaboration_score,
    trait_evidence_elaboration_score_status, trait_organization_purpose_score,
    trait_organization_purpose_score_status, trait_conventions_score, trait_conventions_score_status,
    administered_at,
    submitted,
    submitted_at,
    number_of_visits,
    response_duration,
    response_content_type,
    page_number,
    page_visits,
    page_time,
    response_type_id,
    created
  )
    SELECT
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
      OLD.trait_conventions_score_status,
      OLD.administered_at,
      OLD.submitted,
      OLD.submitted_at,
      OLD.number_of_visits,
      OLD.response_duration,
      OLD.response_content_type,
      OLD.page_number,
      OLD.page_visits,
      OLD.page_time,
      OLD.response_type_id,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

-- audit_exam_item delete trigger
DROP TRIGGER trg__exam_item__delete;

CREATE TRIGGER trg__exam_item__delete
BEFORE DELETE ON exam_item
FOR EACH ROW
  INSERT INTO audit_exam_item (
    action, database_user, exam_item_id, exam_id, item_id, score,
    score_status, position, response, trait_evidence_elaboration_score,
    trait_evidence_elaboration_score_status, trait_organization_purpose_score,
    trait_organization_purpose_score_status, trait_conventions_score, trait_conventions_score_status,
    administered_at,
    submitted,
    submitted_at,
    number_of_visits,
    response_duration,
    response_content_type,
    page_number,
    page_visits,
    page_time,
    response_type_id,
    created
  )
    SELECT
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
      OLD.trait_conventions_score_status,
      OLD.administered_at,
      OLD.submitted,
      OLD.submitted_at,
      OLD.number_of_visits,
      OLD.response_duration,
      OLD.response_content_type,
      OLD.page_number,
      OLD.page_visits,
      OLD.page_time,
      OLD.response_type_id,
      OLD.created
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';
