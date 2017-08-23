-- Load extracted records from CSV

use legacy_load;

LOAD DATA FROM S3 's3://rdw-migrate/extract_dim_asmt.csv'
INTO TABLE dim_asmt
FIELDS TERMINATED BY ',' IGNORE 1 LINES
(asmt_rec_id, asmt_guid, asmt_type, asmt_period, asmt_period_year, asmt_version, asmt_subject, effective_date, asmt_claim_1_name, asmt_claim_2_name, asmt_claim_3_name, asmt_claim_4_name, asmt_perf_lvl_name_1, asmt_perf_lvl_name_2, asmt_perf_lvl_name_3, asmt_perf_lvl_name_4, asmt_perf_lvl_name_5, asmt_claim_perf_lvl_name_1, asmt_claim_perf_lvl_name_2, asmt_claim_perf_lvl_name_3, asmt_score_min, asmt_score_max, asmt_claim_1_score_min, asmt_claim_1_score_max, asmt_claim_2_score_min, asmt_claim_2_score_max, asmt_claim_3_score_min, asmt_claim_3_score_max, @claim_4_score_min, @claim_4_score_max, asmt_cut_point_1, asmt_cut_point_2, asmt_cut_point_3, @cut_point_4, from_date, to_date, rec_status, batch_guid)
SET warehouse_load_id = 1,
  asmt_claim_4_score_min := IF(@claim_4_score_min = '', NULL, @claim_4_score_min),
  asmt_claim_4_score_max := IF(@claim_4_score_max = '', NULL, @claim_4_score_max),
  asmt_cut_point_4 := IF(@cut_point_4 = '', NULL, @cut_point_4);

# Query OK, 296 rows affected, 338 warnings (0.20 sec)
# Records: 296  Deleted: 0  Skipped: 0  Warnings: 0

