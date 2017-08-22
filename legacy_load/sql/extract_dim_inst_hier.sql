-- example run
-- psql -h localhost -U edware -d edware -a -f extract_dim_inst_hier.sql

-- use the ca schema in srl-db-master-003
set SEARCH_PATH to ca;

-- use the edware schema to test in dev
-- SET SEARCH_PATH TO edware;

-- Extract current records to CSV
-- copy does not like multiline statements
\copy (SELECT i.inst_hier_rec_id, i.state_code, i.district_id, i.district_name, i.school_id, i.school_name, i.from_date, i.to_date, i.rec_status, i.batch_guid FROM dim_inst_hier i WHERE i.rec_status = 'C') TO '/mnt/pgsql/rdw-migrate/extract_dim_inst_hier.csv' WITH CSV HEADER;