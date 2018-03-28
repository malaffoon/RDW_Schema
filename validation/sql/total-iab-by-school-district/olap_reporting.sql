SELECT
    ex.count,
    ex.school_id,
    UPPER(d.name),
    UPPER(sch.name)
  FROM (
         SELECT
           count(*) AS count,
           school_id
         FROM fact_student_iab_exam e
         GROUP BY school_id
       ) ex
    JOIN school sch ON sch.id = ex.school_id
    JOIN district d ON d.id = sch.district_id
  ORDER BY ex.count, ex.school_id;