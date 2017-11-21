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
           JOIN asmt a ON a.id = e.asmt_id
           JOIN school s ON s.id = e.school_id
         WHERE a.type_id = 1
         GROUP BY s.id
       ) ex
    JOIN school sch ON sch.id = ex.id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.id;