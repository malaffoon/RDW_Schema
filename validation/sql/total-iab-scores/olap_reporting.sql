SELECT
    sum(scale_score),
    sum(performance_level)
  FROM fact_student_iab_exam e;