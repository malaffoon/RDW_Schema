SELECT
    count(*),
    e.asmt_id,
    e.school_year,
    ac.code,
    CASE WHEN completeness_id = 2 THEN 'TRUE' ELSE 'FALSE' END
  FROM fact_student_iab_exam e
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  GROUP BY
    e.asmt_id,
    e.school_year,
    ac.code,
    completeness_id
  ORDER BY
    count(*),
    e.asmt_id,
    e.school_year,
    ac.code,
    completeness_id;