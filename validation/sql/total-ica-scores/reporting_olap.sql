SELECT
    sum(scale_score),
    sum(scale_score_std_err),
    sum(performance_level)
  FROM fact_student_ica_exam;