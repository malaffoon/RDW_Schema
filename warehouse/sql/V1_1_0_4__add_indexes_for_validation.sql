USE ${schemaName};

-- NOTE: these two indexes significantly improve the validation scripts run time.
-- If you need to improve ingest performance when DB is a bottleneck, consider dropping them and re-creating during the validation run time
ALTER TABLE exam ADD INDEX idx__exam__student_school_year_asmt (student_id, school_year, asmt_id);
ALTER TABLE exam ADD INDEX idx__exam__type_deleted_student_scale_score_scale_score_std_err_performance_level (type_id, deleted, student_id, scale_score, scale_score_std_err, performance_level);