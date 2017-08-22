/**
** 	Initial script for the SBAC Reporting Data Legacy Load schema
**
** Open Items:
** 1. How to relate old asm to the loaded one: asmt_guid does not work.
** 2. How to map the claims (JSON or asmt table)
** 3. [DONE] For the overlapping data - does not matter, seem to be identical
** 4. [DONE] Student data: what takes precedence : dim_student or fact tables? - does not matter, seem to be identical
** 5. [DONE] Opportunity - derive from the same asmt, date_taken_year and student and diff date, start from 0 and increment
** 6. [DONE] Session id - hardcode to 'legacy'
** 7. what is the largest chunk of records in one transaction and how to chunk the data for updates/inserts?
**   stored procedure or java?
**   some resources to check out: https://stackoverflow.com/questions/29754570/bulk-update-to-an-unindexed-column-in-a-large-innodb-table
**   http://mysql.rjweb.org/doc.php/deletebig
** 8. how to assign import ids for migrate. Note: in the import table somehow capture that this is legacy migration
** 9. add support for the 'catch up' load
** 10. Mapping of the old accommodations to the new codes:
**  acc_asl_video_embed smallint NOT NULL,                          TDS_ASL1
**  acc_braile_embed smallint NOT NULL,                             ENU-Braille
**  acc_closed_captioning_embed smallint NOT NULL,                  TDS_ClosedCap1
**  acc_text_to_speech_embed smallint NOT NULL,                     TDS_TTS_Stim&amp;TDS_TTS_Item
**  acc_abacus_nonembed smallint NOT NULL,                          NEA_Abacus
**  acc_alternate_response_options_nonembed smallint NOT NULL,      NEA_AR
**  acc_calculator_nonembed smallint NOT NULL,                      NEA_Calc
**  acc_multiplication_table_nonembed smallint NOT NULL,            NEA_MT
**  acc_print_on_demand_nonembed smallint NOT NULL,                 TDS_PoD_Stim
**  acc_print_on_demand_items_nonembed smallint NOT NULL,           TDS_PoD_Item
**  acc_read_aloud_nonembed smallint NOT NULL,                      NEA_RA_Stimuli
**  acc_scribe_nonembed smallint NOT NULL,                          NEA_SC_WritItems
**  acc_speech_to_text_nonembed smallint NOT NULL,                  NEA_STT
**  acc_streamline_mode smallint NOT NULL,                          TDS_SLM1
**  acc_noise_buffer_nonembed smallint NOT NULL,                    NEDS_NoiseBuf
**
**/

ALTER DATABASE ${schemaName} CHARACTER SET utf8 COLLATE utf8_unicode_ci;

USE ${schemaName};

CREATE TABLE IF NOT EXISTS dim_inst_hier (
  inst_hier_rec_id bigint NOT NULL PRIMARY KEY,
  state_code varchar(2) NOT NULL,
  district_id varchar(40) NOT NULL,
  district_name varchar(60) NOT NULL,
  school_id varchar(40) NOT NULL,
  school_name varchar(60) NOT NULL,
  from_date varchar(8) NOT NULL,
  to_date varchar(8),
#   rec_status varchar(1) NOT NULL,
  batch_guid varchar(36) NOT NULL,

# used for loading into warehouse
  warehouse_school_id int
);

CREATE TABLE IF NOT EXISTS dim_asmt (
  asmt_rec_id bigint NOT NULL PRIMARY KEY,
  asmt_guid varchar(255) NOT NULL,
  asmt_type varchar(32) NOT NULL,
  asmt_period varchar(32),
  asmt_period_year smallint NOT NULL,
  asmt_version varchar(40) NOT NULL,
  asmt_subject varchar(64) NOT NULL,
  effective_date varchar(8) NOT NULL,
  asmt_claim_1_name varchar(128),
  asmt_claim_2_name varchar(128),
  asmt_claim_3_name varchar(128),
  asmt_claim_4_name varchar(128),
#   asmt_perf_lvl_name_1 varchar(25),
#   asmt_perf_lvl_name_2 varchar(25),
#   asmt_perf_lvl_name_3 varchar(25),
#   asmt_perf_lvl_name_4 varchar(25),
#   asmt_perf_lvl_name_5 varchar(25),
#   asmt_claim_perf_lvl_name_1 varchar(128),
#   asmt_claim_perf_lvl_name_2 varchar(128),
#   asmt_claim_perf_lvl_name_3 varchar(128),
#   asmt_score_min smallint NOT NULL,
#   asmt_score_max smallint NOT NULL,
#   asmt_claim_1_score_min smallint NOT NULL,
#   asmt_claim_1_score_max smallint NOT NULL,
#   asmt_claim_2_score_min smallint NOT NULL,
#   asmt_claim_2_score_max smallint NOT NULL,
#   asmt_claim_3_score_min smallint NOT NULL,
#   asmt_claim_3_score_max smallint NOT NULL,
#   asmt_claim_4_score_min smallint,
#   asmt_claim_4_score_max smallint,
#   asmt_cut_point_1 smallint,
#   asmt_cut_point_2 smallint,
#   asmt_cut_point_3 smallint,
#   asmt_cut_point_4 smallint,
  from_date varchar(8) NOT NULL,
  to_date varchar(8),
#   rec_status varchar(1) NOT NULL,
  batch_guid varchar(36) NOT NULL,

# used for loading into warehouse
  warehouse_asmt_id int
);


CREATE TABLE IF NOT EXISTS dim_student (
  student_rec_id bigint NOT NULL PRIMARY KEY,
  student_id varchar(40) NOT NULL,
#   external_student_id varchar(40),
  first_name varchar(35),
  middle_name varchar(35),
  last_name varchar(35),
  birthdate varchar(8),
  sex varchar(10) NOT NULL,
#   group_1_id varchar(40),
#   group_1_text varchar(60),
#   group_2_id varchar(40),
#   group_2_text varchar(60),
#   group_3_id varchar(40),
#   group_3_text varchar(60),
#   group_4_id varchar(40),
#   group_4_text varchar(60),
#   group_5_id varchar(40),
#   group_5_text varchar(60),
#   group_6_id varchar(40),
#   group_6_text varchar(60),
#   group_7_id varchar(40),
#   group_7_text varchar(60),
#   group_8_id varchar(40),
#   group_8_text varchar(60),
#   group_9_id varchar(40),
#   group_9_text varchar(60),
#   group_10_id varchar(40),
#   group_10_text varchar(60),
  dmg_eth_derived smallint,
  dmg_eth_hsp tinyint,
  dmg_eth_ami tinyint,
  dmg_eth_asn tinyint,
  dmg_eth_blk tinyint,
  dmg_eth_pcf tinyint,
  dmg_eth_wht tinyint,
  dmg_eth_2om tinyint,
  dmg_prg_iep tinyint,
  dmg_prg_lep tinyint,
  dmg_prg_504 tinyint,
  dmg_sts_ecd tinyint,
  dmg_sts_mig tinyint,
  from_date varchar(8) NOT NULL,
  to_date varchar(8),
#   rec_status varchar(1) NOT NULL,
  batch_guid varchar(36) NOT NULL,

# used for loading into warehouse
  warehouse_student_id int
);

CREATE TABLE IF NOT EXISTS fact_asmt_outcome_vw (
  asmt_outcome_vw_rec_id bigint NOT NULL PRIMARY KEY,
  asmt_rec_id bigint NOT NULL,
  student_rec_id bigint NOT NULL,
  inst_hier_rec_id bigint NOT NULL,
  asmt_guid varchar(255) NOT NULL,
  student_id varchar(40) NOT NULL,
  state_code varchar(2) NOT NULL,
  district_id varchar(40) NOT NULL,
  school_id varchar(40) NOT NULL,
#   where_taken_id varchar(40),
#   where_taken_name varchar(60),
  asmt_type varchar(32) NOT NULL,
  asmt_year smallint NOT NULL,
  asmt_subject varchar(64) NOT NULL,
  asmt_grade varchar(10) NOT NULL,
  enrl_grade varchar(10) NOT NULL,
  date_taken varchar(8) NOT NULL,
  date_taken_day smallint NOT NULL,
  date_taken_month smallint NOT NULL,
  date_taken_year smallint NOT NULL,
  asmt_score smallint NOT NULL,
  asmt_score_range_min smallint NOT NULL,
#   asmt_score_range_max smallint NOT NULL,
  asmt_perf_lvl smallint NOT NULL,
  asmt_claim_1_score smallint,
  asmt_claim_1_score_range_min smallint,
#   asmt_claim_1_score_range_max smallint,
  asmt_claim_1_perf_lvl smallint,
  asmt_claim_2_score smallint,
  asmt_claim_2_score_range_min smallint,
#   asmt_claim_2_score_range_max smallint,
  asmt_claim_2_perf_lvl smallint,
  asmt_claim_3_score smallint,
  asmt_claim_3_score_range_min smallint,
#   asmt_claim_3_score_range_max smallint,
  asmt_claim_3_perf_lvl smallint,
  asmt_claim_4_score smallint,
  asmt_claim_4_score_range_min smallint,
#   asmt_claim_4_score_range_max smallint,
  asmt_claim_4_perf_lvl smallint,
  sex varchar(10) NOT NULL,
  dmg_eth_derived smallint,
  dmg_eth_hsp tinyint,
  dmg_eth_ami tinyint,
  dmg_eth_asn tinyint,
  dmg_eth_blk tinyint,
  dmg_eth_pcf tinyint,
  dmg_eth_wht tinyint,
  dmg_eth_2om tinyint,
  dmg_prg_iep tinyint,
  dmg_prg_lep tinyint,
  dmg_prg_504 tinyint,
  dmg_sts_ecd tinyint,
  dmg_sts_mig tinyint,
  acc_asl_video_embed smallint NOT NULL,
  acc_braile_embed smallint NOT NULL,
  acc_closed_captioning_embed smallint NOT NULL,
  acc_text_to_speech_embed smallint NOT NULL,
  acc_abacus_nonembed smallint NOT NULL,
  acc_alternate_response_options_nonembed smallint NOT NULL,
  acc_calculator_nonembed smallint NOT NULL,
  acc_multiplication_table_nonembed smallint NOT NULL,
  acc_print_on_demand_nonembed smallint NOT NULL,
  acc_print_on_demand_items_nonembed smallint NOT NULL,
  acc_read_aloud_nonembed smallint NOT NULL,
  acc_scribe_nonembed smallint NOT NULL,
  acc_speech_to_text_nonembed smallint NOT NULL,
  acc_streamline_mode smallint NOT NULL,
  acc_noise_buffer_nonembed smallint NOT NULL,
  from_date varchar(8) NOT NULL,
  to_date varchar(8),
#   rec_status varchar(1) NOT NULL,
  batch_guid varchar(36) NOT NULL,
  complete tinyint,
  administration_condition varchar(2)
);


CREATE TABLE IF NOT EXISTS fact_block_asmt_outcome (
  asmt_outcome_rec_id bigint NOT NULL PRIMARY KEY,
  asmt_rec_id bigint NOT NULL,
  student_rec_id bigint NOT NULL,
  inst_hier_rec_id bigint NOT NULL,
  asmt_guid varchar(255) NOT NULL,
  student_id varchar(40) NOT NULL,
  state_code varchar(2) NOT NULL,
  district_id varchar(40) NOT NULL,
  school_id varchar(40) NOT NULL,
#   where_taken_id varchar(40),
#   where_taken_name varchar(60),
  asmt_type varchar(32) NOT NULL,
  asmt_year smallint NOT NULL,
  asmt_subject varchar(64) NOT NULL,
  asmt_grade varchar(10) NOT NULL,
  enrl_grade varchar(10) NOT NULL,
  date_taken varchar(8) NOT NULL,
  date_taken_day smallint NOT NULL,
  date_taken_month smallint NOT NULL,
  date_taken_year smallint NOT NULL,
  asmt_claim_1_score smallint,
  asmt_claim_1_score_range_min smallint,
#   asmt_claim_1_score_range_max smallint,
  asmt_claim_1_perf_lvl smallint,
  sex varchar(10) NOT NULL,
  dmg_eth_derived smallint,
  dmg_eth_hsp tinyint,
  dmg_eth_ami tinyint,
  dmg_eth_asn tinyint,
  dmg_eth_blk tinyint,
  dmg_eth_pcf tinyint,
  dmg_eth_wht tinyint,
  dmg_eth_2om tinyint,
  dmg_prg_iep tinyint,
  dmg_prg_lep tinyint,
  dmg_prg_504 tinyint,
  dmg_sts_ecd tinyint,
  dmg_sts_mig tinyint,
  acc_asl_video_embed smallint NOT NULL,
  acc_braile_embed smallint NOT NULL,
  acc_closed_captioning_embed smallint NOT NULL,
  acc_text_to_speech_embed smallint NOT NULL,
  acc_abacus_nonembed smallint NOT NULL,
  acc_alternate_response_options_nonembed smallint NOT NULL,
  acc_calculator_nonembed smallint NOT NULL,
  acc_multiplication_table_nonembed smallint NOT NULL,
  acc_print_on_demand_nonembed smallint NOT NULL,
  acc_print_on_demand_items_nonembed smallint NOT NULL,
  acc_read_aloud_nonembed smallint NOT NULL,
  acc_scribe_nonembed smallint NOT NULL,
  acc_speech_to_text_nonembed smallint NOT NULL,
  acc_streamline_mode smallint NOT NULL,
  acc_noise_buffer_nonembed smallint NOT NULL,
  from_date varchar(8) NOT NULL,
  to_date varchar(8),
  rec_status varchar(1) NOT NULL,
  batch_guid varchar(36) NOT NULL,
  complete tinyint,
  administration_condition varchar(2)
);