USE reporting;

-- verify that migrate has not failed
SELECT * FROM migrate WHERE status = -20;

-- get to slowest migrates to check the run time speed
SELECT timestampdiff(SECOND, created, updated) runtime_in_sec
 FROM migrate
   WHERE cast(created AS DATE) = CURDATE() -- or a specific date '2017-07-04'
 ORDER BY runtime_in_sec DESC
 LIMIT 5;