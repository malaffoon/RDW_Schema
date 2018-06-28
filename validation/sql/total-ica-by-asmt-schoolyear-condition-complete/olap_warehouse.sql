SELECT
  count,
  asmt_id,
  school_year,
  CASE WHEN ac.code IS NULL THEN 'NULL' ELSE ac.code END AS code,
  CASE WHEN completeness_id IS NULL THEN 'NULL' WHEN completeness_id = 2 THEN 'TRUE' ELSE 'FALSE' END AS completeness_id
FROM  (
        SELECT
          count(*) as count,
          e1.asmt_id,
          e1.school_year,
          e1.administration_condition_id,
          e1.completeness_id
        FROM exam AS e1
          LEFT OUTER JOIN exam AS e2
            ON e1.student_id = e2.student_id
               AND (e1.completed_at < e2.completed_at OR (e1.completed_at = e2.completed_at AND e1.Id > e2.Id))
               AND e1.school_year = e2.school_year
               AND e1.asmt_id = e2.asmt_id
               AND e2.deleted = 0 AND e2.scale_score IS NOT NULL AND e2.scale_score_std_err IS NOT NULL AND e2.performance_level IS NOT NULL
        WHERE e2.student_id IS NULL AND e1.type_id = 1
              AND e1.deleted = 0 AND e1.scale_score IS NOT NULL AND e1.scale_score_std_err IS NOT NULL AND e1.performance_level IS NOT NULL
        GROUP BY
          e1.asmt_id,
          e1.school_year,
          e1.administration_condition_id,
          e1.completeness_id
      )  e
  LEFT JOIN administration_condition ac ON e.administration_condition_id = ac.id
ORDER BY count, asmt_id, school_year, code, completeness_id;