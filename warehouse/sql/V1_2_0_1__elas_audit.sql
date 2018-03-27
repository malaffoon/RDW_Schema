-- Flyway script to add ELAS (English Language Acquisition Status) to audit tables

USE ${schemaName};

-- change LEP to be optional and add ELAS
ALTER TABLE audit_exam
  MODIFY COLUMN lep TINYINT NULL,
  ADD COLUMN elas_id TINYINT NULL,
  ADD COLUMN elas_start_at DATE NULL;

DROP TRIGGER trg__exam__update;
CREATE TRIGGER trg__exam__update
  BEFORE UPDATE ON exam
  FOR EACH ROW
  INSERT INTO audit_exam (action, database_user, exam_id, type_id, school_year, asmt_id, asmt_version,
                          opportunity, oppId, completeness_id, administration_condition_id, session_id, scale_score,
                          scale_score_std_err, performance_level, completed_at, import_id, update_import_id, deleted,
                          created, updated, grade_id, student_id, school_id, iep, lep, section504,
                          economic_disadvantage, migrant_status, eng_prof_lvl, t3_program_type, language_code,
                          prim_disability_type, status_date, elas_id, elas_start_at,
                          examinee_id, deliver_mode, hand_score_project, contract, test_reason,
                          assessment_admin_started_at, started_at, force_submitted_at, status,
                          item_count, field_test_count, pause_count, grace_period_restarts, abnormal_starts,
                          test_window_id, test_administrator_id, responsible_organization_name, test_administrator_name,
                          session_platform_user_agent, test_delivery_server, test_delivery_db, window_opportunity_count,
                          theta_score, theta_score_std_err)
    SELECT 'update', USER(), OLD.id, OLD.type_id, OLD.school_year, OLD.asmt_id, OLD.asmt_version,
      OLD.opportunity, OLD.oppId, OLD.completeness_id, OLD.administration_condition_id, OLD.session_id, OLD.scale_score,
      OLD.scale_score_std_err, OLD.performance_level, OLD.completed_at, OLD.import_id, OLD.update_import_id, OLD.deleted,
      OLD.created, OLD.updated, OLD.grade_id, OLD.student_id, OLD.school_id, OLD.iep, OLD.lep, OLD.section504,
      OLD.economic_disadvantage, OLD.migrant_status, OLD.eng_prof_lvl, OLD.t3_program_type, OLD.language_code,
      OLD.prim_disability_type, OLD.status_date, OLD.elas_id, OLD.elas_start_at,
      OLD.examinee_id, OLD.deliver_mode, OLD.hand_score_project, OLD.contract, OLD.test_reason,
      OLD.assessment_admin_started_at, OLD.started_at, OLD.force_submitted_at, OLD.status,
      OLD.item_count, OLD.field_test_count, OLD.pause_count, OLD.grace_period_restarts, OLD.abnormal_starts,
      OLD.test_window_id, OLD.test_administrator_id, OLD.responsible_organization_name, OLD.test_administrator_name,
      OLD.session_platform_user_agent, OLD.test_delivery_server, OLD.test_delivery_db, OLD.window_opportunity_count,
      OLD.theta_score, OLD.theta_score_std_err
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';

DROP TRIGGER trg__exam__delete;
CREATE TRIGGER trg__exam__delete
  BEFORE DELETE ON exam
  FOR EACH ROW
  INSERT INTO audit_exam (action, database_user, exam_id, type_id, school_year, asmt_id, asmt_version,
                          opportunity, oppId, completeness_id, administration_condition_id, session_id, scale_score,
                          scale_score_std_err, performance_level, completed_at, import_id, update_import_id, deleted,
                          created, updated, grade_id, student_id, school_id, iep, lep, section504,
                          economic_disadvantage, migrant_status, eng_prof_lvl, t3_program_type, language_code,
                          prim_disability_type, status_date, elas_id, elas_start_at,
                          examinee_id, deliver_mode, hand_score_project, contract, test_reason,
                          assessment_admin_started_at, started_at, force_submitted_at, status,
                          item_count, field_test_count, pause_count, grace_period_restarts, abnormal_starts,
                          test_window_id, test_administrator_id, responsible_organization_name, test_administrator_name,
                          session_platform_user_agent, test_delivery_server, test_delivery_db, window_opportunity_count,
                          theta_score, theta_score_std_err)
    SELECT 'delete', USER(), OLD.id, OLD.type_id, OLD.school_year, OLD.asmt_id, OLD.asmt_version,
      OLD.opportunity, OLD.oppId, OLD.completeness_id, OLD.administration_condition_id, OLD.session_id, OLD.scale_score,
      OLD.scale_score_std_err, OLD.performance_level, OLD.completed_at, OLD.import_id, OLD.update_import_id, OLD.deleted,
      OLD.created, OLD.updated, OLD.grade_id, OLD.student_id, OLD.school_id, OLD.iep, OLD.lep, OLD.section504,
      OLD.economic_disadvantage, OLD.migrant_status, OLD.eng_prof_lvl, OLD.t3_program_type, OLD.language_code,
      OLD.prim_disability_type, OLD.status_date, OLD.elas_id, OLD.elas_start_at,
      OLD.examinee_id, OLD.deliver_mode, OLD.hand_score_project, OLD.contract, OLD.test_reason,
      OLD.assessment_admin_started_at, OLD.started_at, OLD.force_submitted_at, OLD.status,
      OLD.item_count, OLD.field_test_count, OLD.pause_count, OLD.grace_period_restarts, OLD.abnormal_starts,
      OLD.test_window_id, OLD.test_administrator_id, OLD.responsible_organization_name, OLD.test_administrator_name,
      OLD.session_platform_user_agent, OLD.test_delivery_server, OLD.test_delivery_db, OLD.window_opportunity_count,
      OLD.theta_score, OLD.theta_score_std_err
    FROM setting s
    WHERE s.name = 'AUDIT_TRIGGER_ENABLE' AND s.value = 'TRUE';
