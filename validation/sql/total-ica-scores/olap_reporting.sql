SELECT
    sum(scale_score),
    sum(scale_score_std_err),
    sum(performance_level)
  FROM fact_student_exam e
    JOIN asmt a ON e.asmt_id = a.id
  WHERE a.type_id = 1;