SELECT
    count(*),
    e.asmt_id,
    e.school_year,
    ac.code,
    CASE WHEN e.completeness_id = 2 THEN 'TRUE' ELSE 'FALSE' END
  FROM exam e
    JOIN administration_condition ac ON e.administration_condition_id = ac.id
  WHERE e.type_id = 2
    AND e.deleted = 0
  GROUP BY
    e.asmt_id,
    e.school_year,
    e.administration_condition_id,
    e.completeness_id
  ORDER BY count(*), e.asmt_id;