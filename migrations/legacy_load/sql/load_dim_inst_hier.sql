-- Load extracted records from CSV

use legacy_load;

-- Test loading local
-- LOAD DATA LOCAL INFILE '/mnt/pgsql/rdw-migrate/extract_dim_inst_hier.csv'
-- INTO TABLE dim_inst_hier
-- FIELDS TERMINATED BY ',' IGNORE 1 LINES
-- (inst_hier_rec_id, state_code, district_id, district_name, school_id, school_name, from_date, to_date, rec_status, batch_guid)
-- SET warehouse_load_id = 1;

-- Load from S3
LOAD DATA FROM S3 's3://rdw-migrate/updates/100/extract_dim_inst_hier.csv'
INTO TABLE dim_inst_hier
FIELDS TERMINATED BY ',' IGNORE 1 LINES
(inst_hier_rec_id, state_code, district_id, district_name, school_id, school_name, from_date, to_date, rec_status, batch_guid)
SET warehouse_load_id = 100;
