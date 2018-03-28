select count(*) from (
  SELECT DISTINCT
    school_year,
    asmt_id,
    student_id
  FROM exam
  where type_id = 1
        AND deleted = 0
        AND scale_score IS NOT NULL
        AND scale_score_std_err IS NOT NULL
        AND performance_level IS NOT NULL
) a;