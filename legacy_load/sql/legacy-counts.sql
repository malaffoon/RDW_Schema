-- use the ca schema in srl-db-master-003
set SEARCH_PATH to ca;

-- use the edware schema to test in dev
-- set SEARCH_PATH to edware;

-- Records targeted for migration
select
  ( SELECT count(0) FROM fact_asmt_outcome_vw fa WHERE fa.rec_status = 'C' ) as fact_asmt_outcome_vw,
  ( SELECT count(0) FROM fact_block_asmt_outcome b WHERE b.rec_status = 'C' ) as fact_block_asmt_outcome,
  ( SELECT count(0) FROM dim_asmt a WHERE a.rec_status = 'C' ) as dim_asmt,
  ( SELECT count(0) FROM dim_student s WHERE s.rec_status = 'C' ) as dim_student,
  ( SELECT count(0) FROM dim_inst_hier i WHERE i.rec_status = 'C' ) as dim_inst_hier ;

-- All records by status
SELECT fa.rec_status, count(0) FROM fact_asmt_outcome_vw fa GROUP BY fa.rec_status;
SELECT b.rec_status, count(0) FROM fact_block_asmt_outcome b GROUP BY b.rec_status;
SELECT a.rec_status, count(0) FROM dim_asmt a GROUP BY a.rec_status;
SELECT s.rec_status, count(0) FROM dim_student s GROUP BY s.rec_status;
SELECT i.rec_status, count(0) FROM dim_inst_hier i GROUP BY i.rec_status;

