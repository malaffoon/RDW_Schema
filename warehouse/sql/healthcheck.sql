USE warehouse;

-- verify that there is no ACCEPTED imports that are older than the given time
SELECT *
 FROM import
 WHERE status = 0
      AND TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP(6), updated) > 60
 ORDER BY id;

-- count ACCEPTED imports that are older than the given time
SELECT count(*)
 FROM import
 WHERE status = 0 AND TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP(6), updated) > 60;

-- get a breakdown of the failed imports by status and date
SELECT
  count(*),
  i.status,
  s.name AS status_name,
  cast(i.updated AS DATE)
 FROM import i
   JOIN import_status s ON i.status = s.id
 WHERE status < 0 AND cast(i.updated AS DATE) = CURDATE() -- or a specific date '2017-07-04'
 GROUP BY i.status, s.name, cast(i.updated AS DATE);