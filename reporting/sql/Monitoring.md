## Migrate Monitoring instructions
This document has SQL to monitor migrate health. 

The migrate is controlled by the `migrate` table in the `reporting` database. 

```sql
use reporting;
```
All queries below assume to be executed on the `repoting` schema.

#### Monitor migrate failures
The migrate process is managed by the “migrate-reporting” service. 
The service records its status into the table. For all possible migrate statuses please refer to `migrate_status` table:
```sql
select * from migrate_status;
```

The service will suspend itself if there is a failure. To check for the failure, run the following:
```sql
SELECT * FROM migrate WHERE status = -20;
```

#### Monitor migrate speed
The  “migrate-reporting” service continuously migrates newly imported data from `warehouse` to `reporting`. 

To monitor the processing speed of the successful migrates on any given day run:
```sql
SELECT timestampdiff(SECOND, created, updated) runtime_in_sec
 FROM migrate
   WHERE status = 20 AND cast(created AS DATE) = CURDATE() -- or a specific date '2017-07-04'
 ORDER BY id;
```
To find top 5 slowest successful migrates on any given day run:
```sql
 SELECT timestampdiff(SECOND, created, updated) runtime_in_sec
  FROM migrate
    WHERE status = 20 AND cast(created AS DATE) = CURDATE() -- or a specific date '2017-07-04'
  ORDER BY runtime_in_sec DESC
  LIMIT 5;
```  