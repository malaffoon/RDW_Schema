## Monitoring instructions
This document has SQL to monitor the system health. 

### Ingest Monitoring
The ingest is controlled by the `import` table in the `warehouse` database. 
```sql
use warehouse;
```
All queries in this section are assumed to be executed on the `warehouse` schema.

#### Monitor ingest failures
The ingest process is managed by multiple “ingest” services. 
The services record the status into the table. For all possible import statuses please refer to `import_status` table:
```sql
select * from import_status;
```
To monitor for failed imports by status on any given day run:
```sql
SELECT
  count(*),
  i.status,
  s.name AS status_name,
  cast(i.updated AS DATE)
FROM import i
   JOIN import_status s ON i.status = s.id
WHERE 
  i.updated >= (CURRENT_DATE - INTERVAL 1 DAY) and i.updated < CURRENT_DATE -- or a specific date '2017-07-04'
  AND status < 0
GROUP by i.status, status_name, cast(i.updated AS DATE);
``` 
If there are failures refer to the Troubleshooting guide to resolve. It is important to review and analyze the failures to make sure that the data is not lost. 

#### Monitor ingest speed
A new ingest request is captured by the ACCEPTED status of the import. Once the data is loaded into the warehouse the status is updated accordingly.
Each ingest is different and hence the processing time will vary, but in general it is expected to take no more than a minute or less.

To monitor for slow imports:
```sql
SELECT count(*) FROM import WHERE status = 0 AND updated > (CURRENT_TIMESTAMP + INTERVAL 60 SECOND);
```
If there are slow imports please refer to the Troubleshooting guide to resolve. 
**This condition requires immediate attention since new test results may not be loaded into the system until it is addressed**.


### Migrate Monitoring
The migrate is controlled by the `migrate` table in the `reporting` database. 
```sql
use reporting;
```
All queries in this section are assumed to be executed on the `reporting` schema.

#### Monitor migrate failures
The migrate process is managed by the “migrate-reporting” service. 
The service records its status into the table. For all possible migrate statuses please refer to `migrate_status` table:
```sql
select * from migrate_status;
```

The service will suspend itself if there is a failure. To check for the failure, run:
```sql
SELECT * FROM migrate WHERE status = -20;
```
If there are failures refer to the Troubleshooting guide to resolve. 
**This condition requires immediate attention since new test results will not be visible in the reporting application until it is resolved**.
 
#### Monitor migrate speed
The  “migrate-reporting” service continuously migrates newly imported data from `warehouse` to `reporting`. 
The data is moved in batches defined by the `migrate`'s `first_at` and `last_at` timestamps. 
Each batch is different and hence the processing time will vary, but in general it is expected to take no more than a minute or less.

To establish an average speed of the migrate for a particular installation, check the processing speed of the successful migrates on any given day:
```sql
SELECT timestampdiff(SECOND, created, updated) runtime_in_sec
FROM migrate
WHERE status = 20 AND
      created >= (CURRENT_DATE - INTERVAL 1 DAY) AND created < CURRENT_DATE; -- or a specific date '2017-07-04'
```
Or check the average processing time over time:
```sql
SELECT avg(timestampdiff(SECOND, created, updated)) avg_runtime_in_sec
FROM migrate
WHERE status = 20 AND created >= '2017-07-04' AND created < '2017-12-04'; -- substitute dates with your values
```

To monitoring the top 5 slowest successful migrates on a day before any given day run the following:
```sql
SELECT timestampdiff(SECOND, created, updated) runtime_in_sec
 FROM migrate
 WHERE status = 20 AND
       created >= (CURRENT_DATE - INTERVAL 1 DAY) AND created < CURRENT_DATE
 ORDER BY runtime_in_sec DESC
 LIMIT 5;
```  
If migrates are taking more than expected number of seconds, or if the monitoring shows a consistent increase in run time over time the system is degrading. 
Refer to the troubleshooting guide for instructions on diagnosing the situation. 
Although not urgent, this will affect the timeliness of the reporting data.
