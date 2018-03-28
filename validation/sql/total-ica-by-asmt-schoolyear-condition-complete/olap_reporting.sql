SELECT
    count(*),
    e.asmt_id,
    e.school_year,
    ac.code,
    CASE WHEN e.completeness_id = 2 THEN 'TRUE' ELSE 'FALSE' END
  FROM fact_student_exam e
    JOIN asmt a ON e.asmt_id = a.id
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
    WHERE a.type_id = 1
  GROUP BY
    e.asmt_id,
    e.school_year,
    ac.code,
    e.completeness_id
  ORDER BY
    count(*),
    e.asmt_id,
    e.school_year,
    ac.code,
    e.completeness_id;