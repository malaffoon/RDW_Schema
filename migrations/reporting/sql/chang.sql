-- This generates a report showing the delay between the test completion time and availability in the reporting system.
--
-- NOTE: completed-at times for ingested test results is probably wrong, offset by 4 hours.
-- NOTE: this is not optimized and is, in fact, pretty slow; careful with it.

use reporting;

SELECT d.name dname, d.natural_id dcode, sc.name sname, sc.natural_id scode, a.natural_id testname,
       e.grade_code grade, st.ssid, e.completed_at, e.updated processed, m.updated available, e.id,
       timestampdiff(SECOND, e.updated, m.updated) secs_to_migrate,
       timestampdiff(MINUTE, e.completed_at, m.updated)-240 view_delay
from exam e
  join student st on st.id = e.student_id
  join asmt a on a.id = e.asmt_id
  join school sc on sc.id = e.school_id
  join district d on d.id = sc.district_id
  join migrate m on m.id = e.migrate_id
where e.updated > '2017-09-05'
order by e.completed_at;
