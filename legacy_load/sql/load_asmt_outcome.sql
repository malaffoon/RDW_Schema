-- Load extracted records from CSV

use legacy_load;

LOAD DATA FROM S3 's3://rdw-migrate/updates/100/extract_fact_asmt_outcome_vw.csv'
INTO TABLE fact_asmt_outcome_vw
FIELDS TERMINATED BY ',' IGNORE 1 LINES
(asmt_outcome_vw_rec_id, asmt_rec_id, student_rec_id, inst_hier_rec_id, asmt_guid, student_id, state_code, district_id, school_id, where_taken_id, where_taken_name, asmt_type, asmt_year, asmt_subject, asmt_grade, enrl_grade, date_taken, date_taken_day, date_taken_month, date_taken_year, asmt_score, asmt_score_range_min, asmt_score_range_max, asmt_perf_lvl, asmt_claim_1_score, asmt_claim_1_score_range_min, asmt_claim_1_score_range_max, asmt_claim_1_perf_lvl, asmt_claim_2_score, asmt_claim_2_score_range_min, asmt_claim_2_score_range_max, asmt_claim_2_perf_lvl, asmt_claim_3_score, asmt_claim_3_score_range_min, asmt_claim_3_score_range_max, asmt_claim_3_perf_lvl, @claim_4_score, @claim_4_score_range_min, @claim_4_score_range_max, @claim_4_perf_lvl, sex, @eth_derived, @eth_hsp, @eth_ami, @eth_asn, @eth_blk, @eth_pcf, @eth_wht, @eth_2om, @prg_iep, @prg_lep, @prg_504, @sts_ecd, @sts_mig, @comp, administration_condition, acc_asl_video_embed, acc_braile_embed, acc_closed_captioning_embed, acc_text_to_speech_embed, acc_abacus_nonembed, acc_alternate_response_options_nonembed, acc_calculator_nonembed, acc_multiplication_table_nonembed, acc_print_on_demand_nonembed, acc_print_on_demand_items_nonembed, acc_read_aloud_nonembed, acc_scribe_nonembed, acc_speech_to_text_nonembed, acc_streamline_mode, acc_noise_buffer_nonembed, from_date, to_date, rec_status, batch_guid)
SET warehouse_load_id = 100,
  asmt_claim_4_score := IF(@claim_4_score = '', NULL, @claim_4_score),
  asmt_claim_4_score_range_min := IF(@claim_4_score_range_min = '', NULL, @claim_4_score_range_min),
  asmt_claim_4_score_range_max := IF(@claim_4_score_range_max = '', NULL, @claim_4_score_range_max),
  asmt_claim_4_perf_lvl := IF(@claim_4_perf_lvl = '', NULL, @claim_4_perf_lvl),
  dmg_eth_derived := IF(@eth_derived IS NULL OR @eth_derived = '', NULL, @eth_derived),
  dmg_eth_hsp := @eth_hsp = 't',
  dmg_eth_ami := @eth_ami = 't',
  dmg_eth_asn := @eth_asn = 't',
  dmg_eth_blk := @eth_blk = 't',
  dmg_eth_pcf := @eth_pcf = 't',
  dmg_eth_wht := @eth_wht = 't',
  dmg_eth_2om := @eth_2om = 't',
  dmg_prg_iep := @prg_iep = 't',
  dmg_prg_lep := @prg_lep = 't',
  dmg_prg_504 := @prg_504 = 't',
  dmg_sts_ecd := @sts_ecd = 't',
  dmg_sts_mig := (CASE @sts_mig WHEN 't' THEN 1 WHEN 'f' THEN 0 ELSE NULL END),
  complete := @comp = 't';
