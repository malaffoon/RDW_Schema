SELECT
    count(*)
  FROM fact_student_exam f
    JOIN asmt a ON f.asmt_id = a.id
  WHERE a.type_id = 1;