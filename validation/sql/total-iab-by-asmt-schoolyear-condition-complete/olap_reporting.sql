SELECT
    count(*),
    e.asmt_id,
    e.school_year,
    CASE WHEN ac.code IS NULL THEN 'NULL' ELSE ac.code END AS code,
    CASE WHEN completeness_id IS NULL THEN 'NULL' WHEN completeness_id = 2 THEN 'TRUE' ELSE 'FALSE' END AS completeness_id
  FROM iab_exam e
    LEFT JOIN administration_condition ac ON e.administration_condition_id = ac.id
  GROUP BY
    e.asmt_id,
    e.school_year,
    ac.code,
    e.completeness_id
  ORDER BY
    count(*),
    e.asmt_id,
    e.school_year,
    code,
    completeness_id;