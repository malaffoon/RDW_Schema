-- example run
-- psql -h localhost -U edware -d edware -a -f extract_dim_student.sql

-- use the ca schema in srl-db-master-003
set SEARCH_PATH to ca;

-- use the edware schema to test in dev
-- SET SEARCH_PATH TO edware;

-- Extract current records to CSV
-- copy does not like multiline statements
\copy (SELECT s.student_rec_id,s.student_id,s.external_student_id,s.first_name,s.middle_name,s.last_name,s.birthdate,s.sex,s.group_1_id,s.group_1_text,s.group_2_id,s.group_2_text,s.group_3_id,s.group_3_text,s.group_4_id,s.group_4_text,s.group_5_id,s.group_5_text,s.group_6_id,s.group_6_text,s.group_7_id,s.group_7_text,s.group_8_id,s.group_8_text,s.group_9_id,s.group_9_text,s.group_10_id,s.group_10_text,s.dmg_eth_derived,s.dmg_eth_hsp,s.dmg_eth_ami,s.dmg_eth_asn,s.dmg_eth_blk,s.dmg_eth_pcf,s.dmg_eth_wht,s.dmg_eth_2om,s.dmg_prg_iep,s.dmg_prg_lep,s.dmg_prg_504,s.dmg_sts_ecd,s.dmg_sts_mig,s.from_date,s.to_date,s.rec_status,s.batch_guid FROM dim_student s WHERE s.rec_status = 'C' AND to_date(from_date, 'YYYYMMDD') > to_date('20170821', 'YYYYMMDD')) TO '/mnt/pgsql/rdw-migrate/updates/100/extract_dim_student.csv' WITH CSV HEADER;