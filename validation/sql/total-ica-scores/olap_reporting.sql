SELECT
    sum(e.scale_score),
    sum(e.performance_level)
  FROM exam e
    JOIN asmt a ON e.asmt_id = a.id
  WHERE a.type_id = 1;