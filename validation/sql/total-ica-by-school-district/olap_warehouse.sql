SELECT
  count,
  school_id,
  UPPER(d.name),
  UPPER(sch.name)
      FROM
         (
           SELECT
             count(*) AS count,
             e1.school_id
           FROM exam AS e1
             LEFT OUTER JOIN exam AS e2
               ON e1.student_id = e2.student_id
                  AND (e1.completed_at < e2.completed_at OR (e1.completed_at = e2.completed_at AND e1.Id > e2.Id))
                  AND e1.school_year = e2.school_year
                  AND e1.asmt_id = e2.asmt_id
                  AND e2.deleted = 0 AND e2.scale_score IS NOT NULL AND e2.scale_score_std_err IS NOT NULL AND e2.performance_level IS NOT NULL
           WHERE e2.student_id IS NULL AND e1.type_id = 1
                 AND e1.deleted = 0 AND e1.scale_score IS NOT NULL AND e1.scale_score_std_err IS NOT NULL AND e1.performance_level IS NOT NULL
           GROUP BY school_id
         ) e
        JOIN school sch ON sch.id = e.school_id
        JOIN district d ON d.id = sch.district_id
ORDER BY count, e.school_id;