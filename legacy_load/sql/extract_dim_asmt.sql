-- example run
-- psql -h localhost -U edware -d edware -a -f extract_dim_asmt.sql

-- use the ca schema in srl-db-master-003
set SEARCH_PATH to ca;

-- use the edware schema to test in dev
-- SET SEARCH_PATH TO edware;

-- Extract current records to CSV
-- copy does not like multiline statements

\copy (SELECT asmt_rec_id,asmt_guid,asmt_type,asmt_period,asmt_period_year,asmt_version,asmt_subject,effective_date,asmt_claim_1_name,asmt_claim_2_name,asmt_claim_3_name,asmt_claim_4_name,asmt_perf_lvl_name_1,asmt_perf_lvl_name_2,asmt_perf_lvl_name_3,asmt_perf_lvl_name_4,asmt_perf_lvl_name_5,asmt_claim_perf_lvl_name_1,asmt_claim_perf_lvl_name_2,asmt_claim_perf_lvl_name_3,asmt_score_min,asmt_score_max,asmt_claim_1_score_min,asmt_claim_1_score_max,asmt_claim_2_score_min,asmt_claim_2_score_max,asmt_claim_3_score_min,asmt_claim_3_score_max,asmt_claim_4_score_min,asmt_claim_4_score_max,asmt_cut_point_1,asmt_cut_point_2,asmt_cut_point_3,asmt_cut_point_4,from_date,to_date,rec_status,batch_guid FROM   dim_asmt a WHERE  a.rec_status = 'C' AND to_date(from_date, 'YYYYMMDD') > to_date('20161024', 'YYYYMMDD')) TO '/mnt/pgsql/rdw-migrate/updates/100/extract_dim_asmt.csv' WITH CSV HEADER;