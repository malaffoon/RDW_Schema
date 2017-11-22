SELECT
    ex.count,
    ex.school_id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           e.school_id
         FROM exam e
           JOIN asmt a ON a.id = e.asmt_id
         WHERE e.type_id = 2
           AND a.deleted = 0
           AND e.deleted = 0
         GROUP BY e.school_id
       ) ex
    JOIN school sch ON sch.id = ex.school_id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.school_id;