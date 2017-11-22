SELECT
    count(*),
    e.asmt_id,
    a.school_year,
    ac.code,
    CASE WHEN completeness_id = 2
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM fact_student_ica_exam e
    JOIN ica_asmt a ON e.asmt_id = a.id
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  GROUP BY
    e.asmt_id,
    a.school_year,
    ac.code,
    completeness_id
  ORDER BY count(*), e.asmt_id;