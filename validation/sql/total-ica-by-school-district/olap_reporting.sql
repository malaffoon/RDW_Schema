SELECT
    ex.count,
    ex.school_id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           e.school_id
         FROM fact_student_exam e
            JOIN asmt a ON e.asmt_id = a.id
            WHERE a.type_id = 1
         GROUP BY e.school_id
       ) ex
    JOIN school sch ON sch.id = ex.school_id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.school_id;