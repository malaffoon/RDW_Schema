set SEARCH_PATH to ca;

CREATE TABLE IF NOT EXISTS pre_validation
(
  id bigserial,
  testNum int,
  result1 varchar(1000),
  result2 varchar(1000),
  result3 varchar(1000),
  result4 varchar(1000),
  result5 varchar(1000),
  result6 varchar(1000),
  result7 varchar(1000),
  result8 varchar(1000),
  created timestamp default current_timestamp
);

-- TODO: this is an asmt that was not loaded into prod yet
CREATE TABLE IF NOT EXISTS exclude_asmt
(
  guid varchar(1000)
);

INSERT INTO exclude_asmt VALUES
  ('SBAC-IAB-FIXED-G8E-Perf-Explanatory-CompareAncient');


CREATE TABLE IF NOT EXISTS dim_asmt_guid_to_natural_id_mapping (
  guid varchar(255) NOT NULL,
  subject varchar(4) NOT NULL,
  grade varchar(2) NOT NULL,
  natural_id varchar(250) NOT NULL,
  name varchar(250) NOT NULL,
  school_year varchar(9) NOT NULL
);

-- TODO: run asmt_guid_mappings.sql

--  Total counts
INSERT INTO pre_validation(testNum, result1) SELECT 1, 'total_ica';
INSERT INTO pre_validation(testNum, result1)
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*)
  FROM fact_asmt_outcome_vw f
  WHERE rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt);
-- SELECT count(*) FROM exam where type_id = 1;

INSERT INTO pre_validation(testNum, result1) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'total_iab';
INSERT INTO pre_validation(testNum, result1)
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*)
  FROM fact_block_asmt_outcome
  WHERE rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt);
-- SELECT count(*) FROM exam where type_id = 2;

INSERT INTO pre_validation(testNum, result1, result2, result3)  SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'total ica score', 'total std err', 'total perf level';
INSERT INTO pre_validation(testNum, result1, result2, result3)
  SELECT (SELECT max(testNum) FROM pre_validation),
    sum(asmt_score)                        AS total_score,
    sum(asmt_score_range_max - asmt_score) AS total_std_err,
    sum(asmt_perf_lvl)                     AS total_perf_level
  FROM fact_asmt_outcome_vw
  WHERE rec_status = 'C' AND asmt_guid NOT IN (SELECT * FROM exclude_asmt);
-- SELECT sum(scale_score), sum(scale_score_std_err), sum(performance_level) FROM exam where type_id = 1;

INSERT INTO pre_validation(testNum, result1, result2, result3) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'total iab score', 'total std err', 'total perf level';
INSERT INTO pre_validation(testNum, result1, result2, result3)
  SELECT (SELECT max(testNum) FROM pre_validation),
  sum(asmt_claim_1_score)                        AS total_score,
  sum(asmt_claim_1_score_range_max - asmt_claim_1_score) AS total_std_err,
  sum(asmt_claim_1_perf_lvl)                     AS total_perf_level
  FROM fact_block_asmt_outcome
WHERE rec_status = 'C' AND asmt_guid NOT IN (SELECT * FROM exclude_asmt);
-- SELECT sum(scale_score), sum(scale_score_std_err), sum(performance_level) FROM exam where type_id = 2;

INSERT INTO pre_validation(testNum, result1)  SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'total students';
INSERT INTO pre_validation(testNum, result1)
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(DISTINCT student_id)
  FROM dim_student
  WHERE rec_status = 'C';
-- SELECT count(*) FROM student;

-- Exam break down by asmt year, admin condition and complete
INSERT INTO pre_validation(testNum, result1, result2, result3, result4, result5) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'ica exams', 'asmt', 'asmt year', 'admin condition', 'complete';
INSERT INTO pre_validation(testNum, result1, result2, result3, result4, result5)
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*),
    am.name,
    asmt_period_year,
    case when coalesce(f.administration_condition, '') = '' then 'Valid' else administration_condition end as ac,
    case when complete is null then 'f' else complete end as complete
  FROM fact_asmt_outcome_vw f join dim_asmt_guid_to_natural_id_mapping am ON am.guid = f.asmt_guid join dim_asmt da ON am.guid = da.asmt_guid
  WHERE f.rec_status = 'C' and da.rec_status = 'C'
  GROUP BY asmt_period_year, am.name, ac, complete
  ORDER BY  count(*);

-- SELECT count(*),
--   a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- FROM exam e join asmt a ON e.asmt_id = a.id
--   where a.type_id = 1
-- group by  a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- order by   count(*);

INSERT INTO pre_validation(testNum, result1, result2, result3, result4, result5) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'iab exams', 'asmt', 'asmt year', 'admin condition', 'complete';
INSERT INTO pre_validation(testNum, result1, result2, result3, result4, result5)
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*),
    am.name,
    asmt_period_year,
    case when coalesce(f.administration_condition, '') = '' then 'Valid' else administration_condition end as ac,
    case when complete is null then 'f' else complete end as complete
  FROM fact_block_asmt_outcome f join dim_asmt_guid_to_natural_id_mapping am ON am.guid = f.asmt_guid join dim_asmt da ON am.guid = da.asmt_guid
  WHERE f.rec_status = 'C' and da.rec_status = 'C' and f.asmt_guid not in (SELECT * FROM exclude_asmt)
  GROUP BY asmt_period_year, am.name, ac, complete
  ORDER BY  count(*);

-- SELECT count(*),
--   a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- FROM exam e join asmt a ON e.asmt_id = a.id
--   where a.type_id = 2
-- group by  a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- order by   count(*);

--   Exam breakdown by district and school
INSERT INTO pre_validation(testNum, result1, result2, result3, result4) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'ica exams', 'school id', 'district', 'school';
INSERT INTO pre_validation(testNum, result1, result2, result3, result4)
  SELECT (SELECT max(testNum) FROM pre_validation),
    s.count,
    s.school_id,
    h.district_name,
    h.school_name
  FROM (
         SELECT
           count(*) as count,
           school_id,
           district_id
         FROM fact_asmt_outcome_vw
         WHERE rec_status = 'C'
         GROUP BY school_id, district_id
       ) s
    JOIN dim_inst_hier h ON h.school_id = s.school_id and h.district_id = s.district_id where h.rec_status = 'C'
  ORDER BY s.count, school_id;

-- SELECT  s.count,
--   sch.natural_id,
--   d.name,
--   sch.name
-- FROM (
--        SELECT
--          count(*) as count,
--          s.natural_id
--        FROM exam e
--          JOIN asmt a ON a.id = e.asmt_id
--          JOIN school s ON s.id = e.school_id
--        WHERE a.type_id = 1
--        GROUP BY natural_id
--      ) s join school sch ON sch.natural_id = s.natural_id join district d ON d.id = sch.district_id
-- ORDER BY s.count,
--   natural_id;

INSERT INTO pre_validation(testNum, result1, result2, result3, result4) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'iab exams', 'school id', 'district', 'school';
INSERT INTO pre_validation(testNum, result1, result2, result3, result4)
  SELECT (SELECT max(testNum) FROM pre_validation),
    s.count,
    s.school_id,
    h.district_name,
    h.school_name
  FROM (
         SELECT
           count(*) as count,
           school_id,
           district_id
         FROM fact_block_asmt_outcome f
         WHERE rec_status = 'C' and f.asmt_guid not in (SELECT * FROM exclude_asmt)
         GROUP BY school_id, district_id
       ) s
    JOIN dim_inst_hier h ON h.school_id = s.school_id and h.district_id = s.district_id where h.rec_status = 'C'
  ORDER BY  s.count, school_id;

-- SELECT  s.count,
--   sch.natural_id,
--   d.name,
--   sch.name
-- FROM (
--        SELECT
--          count(*) as count,
--          s.natural_id
--        FROM exam e
--          JOIN asmt a ON a.id = e.asmt_id
--          JOIN school s ON s.id = e.school_id
--        WHERE a.type_id = 2
--        GROUP BY natural_id
--      ) s join school sch ON sch.natural_id = s.natural_id join district d ON d.id = sch.district_id
-- ORDER BY s.count,
--   natural_id;

-- Student
INSERT INTO pre_validation(testNum, result1, result2) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'ethnicity count', 'ethnicity';
INSERT INTO pre_validation(testNum, result1, result2)
  SELECT (SELECT max(testNum) FROM pre_validation),
   * FROM (
  SELECT  count(*) AS count, 'HispanicOrLatinoEthnicity' AS code  FROM dim_student where dmg_eth_hsp = 't'  and rec_status = 'C'
  UNION ALL
  SELECT count(*) AS count,'AmericanIndianOrAlaskaNative' AS code FROM dim_student where dmg_eth_ami = 't' and rec_status = 'C'
  UNION ALL
  SELECT count(*) AS count, 'Asian' AS code FROM dim_student where dmg_eth_asn = 't'  and rec_status = 'C'
  UNION ALL
  SELECT count(*) AS count, 'BlackOrAfricanAmerican' AS code FROM dim_student where dmg_eth_blk = 't'  and rec_status = 'C'
  UNION ALL
  SELECT count(*) AS count, 'White' AS code FROM dim_student where dmg_eth_wht = 't'  and rec_status = 'C'
  UNION ALL
  SELECT count(*) AS count, 'DemographicRaceTwoOrMoreRaces' AS code FROM dim_student where dmg_eth_2om = 't'  and rec_status = 'C'
  UNION ALL
  SELECT count(*) AS count, 'NativeHawaiianOrOtherPacificIslander' AS code FROM dim_student where dmg_eth_pcf = 't'  and rec_status = 'C'
) as ethnicity order by count;
-- SELECT count(*), ethnicity_code  FROM student_ethnicity group by ethnicity_code order by count(*);


-- Exam accommodations
INSERT INTO pre_validation(testNum, result1, result2) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'ica accommodations count', 'ethnicity';
INSERT INTO pre_validation(testNum, result1, result2)
SELECT (SELECT max(testNum) FROM pre_validation),
   * FROM (
SELECT  count(*) AS count, 'TDS_ASL1' as code FROM fact_asmt_outcome_vw where acc_asl_video_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'ENU-Braille' as code FROM fact_asmt_outcome_vw where acc_braile_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'TDS_ClosedCap1' as code FROM fact_asmt_outcome_vw where acc_closed_captioning_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'TDS_TTS_Stim&TDS_TTS_Item' as code FROM fact_asmt_outcome_vw where acc_text_to_speech_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_Abacus' as code FROM fact_asmt_outcome_vw where acc_abacus_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_AR' as code FROM fact_asmt_outcome_vw where acc_alternate_response_options_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_Calc' as code FROM fact_asmt_outcome_vw where acc_calculator_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_MT' as code FROM fact_asmt_outcome_vw where acc_multiplication_table_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'TDS_PoD_Stim' as code FROM fact_asmt_outcome_vw where acc_print_on_demand_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'TDS_PoD_Item' as code FROM fact_asmt_outcome_vw where acc_print_on_demand_items_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_RA_Stimuli' as code FROM fact_asmt_outcome_vw where acc_read_aloud_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_SC_WritItems' as code FROM fact_asmt_outcome_vw where acc_scribe_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'NEA_STT' as code FROM fact_asmt_outcome_vw where acc_speech_to_text_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
UNION ALL
SELECT  count(*) AS count, 'TDS_SLM1' as code FROM fact_asmt_outcome_vw where acc_streamline_mode IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
--UNION ALL
--SELECT  count(*) AS count, 'NEDS_NoiseBuf' as code FROM fact_asmt_outcome_vw where acc_noise_buffer_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C'
) as accommodatioms order by count;
-- SELECT count(*), code FROM exam e join exam_available_accommodation ea ON e.id = ea.exam_id join accommodation a ON a.id = ea.accommodation_id where e.type_id = 1 group by ea.accommodation_id order by count(*);


INSERT INTO pre_validation(testNum, result1, result2) SELECT (SELECT max(testNum) FROM pre_validation) + 1, 'iab accommodations count', 'ethnicity';
INSERT INTO pre_validation(testNum, result1, result2)
SELECT (SELECT max(testNum) FROM pre_validation),
   * FROM (
SELECT  count(*) AS count, 'TDS_ASL1' as code FROM fact_block_asmt_outcome where acc_asl_video_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'ENU-Braille' as code FROM fact_block_asmt_outcome where acc_braile_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'TDS_ClosedCap1' as code FROM fact_block_asmt_outcome where acc_closed_captioning_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'TDS_TTS_Stim&TDS_TTS_Item' as code FROM fact_block_asmt_outcome where acc_text_to_speech_embed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_Abacus' as code FROM fact_block_asmt_outcome where acc_abacus_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_AR' as code FROM fact_block_asmt_outcome where acc_alternate_response_options_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_Calc' as code FROM fact_block_asmt_outcome where acc_calculator_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_MT' as code FROM fact_block_asmt_outcome where acc_multiplication_table_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'TDS_PoD_Stim' as code FROM fact_block_asmt_outcome where acc_print_on_demand_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'TDS_PoD_Item' as code FROM fact_block_asmt_outcome where acc_print_on_demand_items_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_RA_Stimuli' as code FROM fact_block_asmt_outcome where acc_read_aloud_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_SC_WritItems' as code FROM fact_block_asmt_outcome where acc_scribe_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'NEA_STT' as code FROM fact_block_asmt_outcome where acc_speech_to_text_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
UNION ALL
SELECT  count(*) AS count, 'TDS_SLM1' as code FROM fact_block_asmt_outcome where acc_streamline_mode IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
--UNION ALL
--SELECT  count(*) AS count, 'NEDS_NoiseBuf' as code FROM fact_block_asmt_outcome where acc_noise_buffer_nonembed IN (6, 7, 8, 15, 16, 17, 24, 25, 26) AND  rec_status = 'C' and asmt_guid not in (SELECT * FROM exclude_asmt)
) as accommodatioms order by count;
--SELECT count(*), code FROM exam e join exam_available_accommodation ea ON e.id = ea.exam_id join accommodation a ON a.id = ea.accommodation_id where e.type_id = 2 group by ea.accommodation_id order by count(*);