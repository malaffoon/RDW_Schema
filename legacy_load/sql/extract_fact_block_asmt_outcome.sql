-- example run
-- psql -h localhost -U edware -d edware -a -f extract_fact_block_asmt_outcome.sql

-- use the ca schema in srl-db-master-003
set SEARCH_PATH to ca;

-- use the edware schema to test in dev
-- SET SEARCH_PATH TO edware;

-- Extract current records to CSV
-- copy does not like multiline statements
\copy (SELECT asmt_outcome_rec_id,asmt_rec_id,student_rec_id,inst_hier_rec_id,asmt_guid,student_id,state_code,district_id,school_id,where_taken_id,where_taken_name,asmt_type,asmt_year,asmt_subject,asmt_grade,enrl_grade,date_taken,date_taken_day,date_taken_month,date_taken_year,asmt_claim_1_score,asmt_claim_1_score_range_min,asmt_claim_1_score_range_max,asmt_claim_1_perf_lvl,sex,dmg_eth_derived,dmg_eth_hsp,dmg_eth_ami,dmg_eth_asn,dmg_eth_blk,dmg_eth_pcf,dmg_eth_wht,dmg_eth_2om,dmg_prg_iep,dmg_prg_lep,dmg_prg_504,dmg_sts_ecd,dmg_sts_mig,complete,administration_condition,acc_asl_video_embed,acc_braile_embed,acc_closed_captioning_embed,acc_text_to_speech_embed,acc_abacus_nonembed,acc_alternate_response_options_nonembed,acc_calculator_nonembed,acc_multiplication_table_nonembed,acc_print_on_demand_nonembed,acc_print_on_demand_items_nonembed,acc_read_aloud_nonembed,acc_scribe_nonembed,acc_speech_to_text_nonembed,acc_streamline_mode,acc_noise_buffer_nonembed,from_date,to_date,rec_status,batch_guid FROM fact_block_asmt_outcome WHERE rec_status = 'C') TO '/mnt/pgsql/rdw-migrate/extract_fact_block_asmt_outcome.csv' WITH CSV HEADER;
