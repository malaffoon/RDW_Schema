SELECT
    ex.count,
    sch.id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           s.id
         FROM exam e
           JOIN school s ON s.id = e.school_id
         WHERE e.type_id = 2
           AND e.deleted = 0
         GROUP BY s.id
       ) ex
    JOIN school sch ON sch.id = ex.id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.id;