SELECT
    count(*),
    a.id,
    a.school_year,
    e.administration_condition_code,
    CASE WHEN e.completeness_code = 'Complete'
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM exam e
    JOIN asmt a ON e.asmt_id = a.id
  WHERE a.type_id = 1
  GROUP BY
    a.id,
    a.school_year,
    e.administration_condition_code,
    e.completeness_code
  ORDER BY count(*), a.id;