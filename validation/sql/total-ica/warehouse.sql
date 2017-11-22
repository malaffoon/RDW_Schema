SELECT
    count(*)
  FROM exam
  WHERE type_id = 1
    AND deleted = 0;