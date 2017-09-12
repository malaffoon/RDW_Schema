## Slow query log

The slow query log is the lowest-overhead way to measure query execution time (https://dev.mysql.com/doc/refman/5.6/en/slow-query-log.html) 
- slow_query_log - enables the log
- long_query_time - configure the threshold to log the data
- log_output - controls the data logged data output location. The data could be configured to be logged into a db table or a file. When 'table' option is
chosen the data is logged into mysql.slow_log table.
- slow_query_log_file - file path, only applicable if the log_output is file

Observation: a server reboot wipes out the logged data.

## SHOW PROFILE command

It is a query profiling tool. It is disabled by default, but can be enabled for the duration of a session (connection) simply by setting a server variable:
(NOTE: This statement is deprecated as of MySQL 5.6.7 and will be removed in a future MySQL release. Use the Performance Schema instead)

```sql
mysql > SET profiling = 1;
```
After this, whenever you issue a statement to the server, it will measure the elapsed time and a few other types of data whenever the query changes from one execution state to another.
It records the profiling information in a temporary table and assigns the statement an integer identifier, starting with 1.

To view the profiled data:
```sql
mysql > SHOW PROFILES;
mysql > SELECT * FROM information_schema.profiling WHERE query_id = 255;
```
The above captures the query’s response time with higher precision, which is nice.
The profile allows you to follow through every step of the query’s execution and see how long it took. 

The SHOW PROFILES displays a list of the most recent statements sent to the server. 
The size of the list is controlled by the profiling_history_size session variable, which has a default value of 15. 
The maximum value is 100. Setting the value to 0 has the practical effect of disabling profiling. 

## Explain EXTENDED
MySQL doesn’t generate byte-code to execute a query, as many other database products do. 
Instead, the query execution plan is actually a tree of instructions that the query execution engine follows to produce the query results. 
The final plan contains enough information to reconstruct the original query. 
If you execute EXPLAIN EXTENDED on a query, followed by SHOW WARNINGS, you’ll see the reconstructed query.

## Performance Schema

The MySQL Performance Schema is a feature for monitoring MySQL Server execution at a low level: https://dev.mysql.com/doc/refman/5.6/en/performance-schema.html.

By default, the Performance Schema is disabled, and you have to turn it on and enable specific instrumentation points (“consumers”) that you wish to collect.
According to some sources, Performance Schema caused around an 8% to 11% overhead even when it was collecting no data, and 19% to 25% with all consumers enabled.

To create schema on MySQL 5.6 follow instructions here https://github.com/mysql/mysql-sys. Note that the last line of the SQL scripts requires super user permissions, that is not available on Aurora. 
But the setting is turned on by default: "SET @@sql_log_bin = @sql_log_bin;"

To enable the performance schema use, you need to configure the server with 
```
performance_schema=ON
```
On Aurora, it will require a server reboot.

There are many tables in the schema. For some examples of SQL against the Performance Schema tables, you can read some of the articles on Oracle engineer Mark Leith’s blog, such as http://www.markleith.co.uk/?p=471.



