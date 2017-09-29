## Tips and Tricks
This document has some SQL tips and tricks.

Just didn't know where else to put this.

#### Creating Fake Groups
Test results don't have group membership and there is no roster information available for legacy data. But the UI is 
oriented around groups. So these queries are a way to hack in some school-based groups.

```sql
use warehouse;

# create import record
insert into import (status, content, contentType, digest, creator) values (0, 5, 'text/plain', left(uuid(), 8), 'dwtest@example.com');
select max(id) from import into @IMPORT_ID;

# create groups, one per school
insert into student_group (name, school_id, school_year, active, creator, import_id, update_import_id)
select concat('S', es.school_id, '-G', es.grade_id) as name, es.school_id, 2017 as school_year, 1 as active,
  'dwtest@example.com' as creator, @IMPORT_ID as import_id, @IMPORT_ID as update_import_id
from exam_student es
  join exam e on e.exam_student_id = es.id
  join asmt a on a.id = e.asmt_id
  join school s on s.id = es.school_id
group by es.school_id;

# put students in groups
insert ignore into student_group_membership (student_group_id, student_id)
select sg.id, es.student_id
from exam_student es
  join student_group sg on sg.school_id = es.school_id;

# trigger migration
update import set status = 1 where id = @IMPORT_ID;
```

After this, there will be a bunch of groups (wait for migrate to move the group data to reporting). 
You'll still need to add your user to some of the groups. This adds the user to the five biggest groups:
```sql
use reporting;

insert into user_student_group (student_group_id, user_login)
select student_group_id, 'dwtest@example.com' from (
  select student_group_id, count(*) as cnt
    from student_group_membership
    group by (student_group_id)
    order by cnt desc limit 5) s;
```

### Reporting Queries

#### Anything By Date

Let's make a sequence of useful dates ...
```sql
CREATE VIEW digits AS SELECT 0 AS digit UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9;
CREATE VIEW numbers AS SELECT ones.digit + tens.digit * 10 + hundreds.digit * 100 AS number FROM digits as ones, digits as tens, digits as hundreds;
CREATE VIEW dates AS SELECT SUBDATE(CURRENT_DATE(), number) AS date FROM numbers;
-- prod is now a collection of all dates from start of production to today 
CREATE VIEW prod as SELECT date FROM dates WHERE date BETWEEN '2017-09-07' AND CURRENT_DATE() ORDER BY date;
```

That sequence can be used to flesh out a by-date report. For example, a simple count of exams updated by date. The 
first query works fine but has gaps for any day exams are not received. So join with the date sequence to fill in the
gaps.
```sql
SELECT DATE(updated) date, COUNT(*) count FROM exam WHERE updated > '2017-09-07' GROUP BY DATE(updated) ORDER BY DATE(updated);

SELECT p.date, IFNULL(s.count, 0) count FROM prod p 
  LEFT JOIN (SELECT DATE(updated) date, COUNT(*) count FROM exam WHERE updated > '2017-09-07' GROUP BY DATE(updated)) s ON s.date=p.date
  ORDER BY p.date; 

-- in theory, a simple right join should do the same thing but performance tanks; have to revisit:
SELECT DATE(e.updated), count(e.id) FROM exam e RIGHT JOIN prod p ON DATE(e.updated) = p.date WHERE e.updated > '2017-09-07' GROUP BY DATE(e.updated);
```

Similarly, find the number of unique schools/students represented by exams received since production started:
```sql
-- cumulative unique schools
SELECT p.date, count(DISTINCT sub.sid) FROM prod p 
  LEFT JOIN (SELECT DATE(e.updated) date, es.school_id sid FROM exam e JOIN exam_student es ON es.id = e.exam_student_id WHERE e.updated > '2017-09-07') sub
    ON sub.date <= p.date
  GROUP BY p.date
  ORDER BY p.date;
  
-- cumulative unique students
SELECT p.date, count(DISTINCT sub.sid) FROM prod p 
  LEFT JOIN (SELECT DATE(e.updated) date, es.student_id sid FROM exam e JOIN exam_student es ON es.id = e.exam_student_id WHERE e.updated > '2017-09-07') sub
    ON sub.date <= p.date
  GROUP BY p.date
  ORDER BY p.date;
```


