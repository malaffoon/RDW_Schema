SELECT
    count(*),
    a.id,
    a.school_year,
    ac.code,
    CASE WHEN e.completeness_id = 2
      THEN 'TRUE'
    ELSE 'FALSE' END
  FROM exam e
    JOIN asmt a ON e.asmt_id = a.id
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  WHERE a.type_id = 2
    AND a.deleted = 0
    AND e.deleted = 0
  GROUP BY
    a.school_year,
    a.id,
    e.administration_condition_id,
    e.completeness_id
  ORDER BY count(*), a.id;