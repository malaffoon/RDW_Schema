SELECT
    s.count,
    sch.id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           s.id
         FROM fact_student_ica_exam e
           JOIN ica_asmt a ON a.id = e.asmt_id
           JOIN school s ON s.id = e.school_id
         GROUP BY s.id
       ) s
    JOIN school sch ON sch.id = s.id
    JOIN district d ON d.id = sch.district_id
  ORDER BY s.count, s.id;