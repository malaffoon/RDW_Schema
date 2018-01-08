select count(*) from (
  SELECT DISTINCT
    school_year,
    asmt_id,
    student_id
  FROM exam e1
  where type_id = 1
        AND deleted = 0
        AND e1.scale_score IS NOT NULL
        AND e1.scale_score_std_err IS NOT NULL
        AND e1.performance_level IS NOT NULL
) a;