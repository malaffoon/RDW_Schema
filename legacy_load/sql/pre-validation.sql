set SEARCH_PATH to edware_ca;

select count(*) from fact_asmt_outcome_vw where rec_status = 'C';
select count(*) from fact_block_asmt_outcome where rec_status = 'C';

SELECT
  sum(asmt_score)                        AS total_score,
  sum(asmt_score_range_max - asmt_score) AS total_std_err,
  sum(asmt_perf_lvl)                     AS total_perf_level
FROM fact_asmt_outcome_vw
WHERE rec_status = 'C';

select count(distinct student_id) from dim_student where rec_status = 'C';
select count(distinct student_id) from fact_asmt_outcome_vw where rec_status = 'C';
select count(distinct student_id) from fact_block_asmt_outcome where rec_status = 'C';

SELECT
  count(*),
  asmt_guid,
  asmt_year,
  administration_condition,
  complete
FROM fact_asmt_outcome_vw
WHERE rec_status = 'C'
GROUP BY asmt_guid, asmt_year, administration_condition, complete
ORDER BY asmt_year, asmt_guid,administration_condition, complete;

SELECT
  count(*),
  asmt_guid,
  asmt_year,
  administration_condition,
  complete
FROM fact_block_asmt_outcome
WHERE rec_status = 'C'
GROUP BY asmt_guid, asmt_year, administration_condition, complete
ORDER BY asmt_year, asmt_guid,administration_condition, complete;

SELECT
  s.*,
  h.district_name,
  h.school_name
FROM (
       SELECT
         count(*),
         school_id,
         asmt_year
       FROM fact_asmt_outcome_vw
       WHERE rec_status = 'C'
       GROUP BY school_id, asmt_year
   ) s
  JOIN dim_inst_hier h ON h.school_id = s.school_id
ORDER BY district_name, school_name, asmt_year;

SELECT
  s.*,
  h.district_name,
  h.school_name
FROM (
       SELECT
         count(*),
         school_id,
         asmt_year
       FROM fact_block_asmt_outcome
       WHERE rec_status = 'C'
       GROUP BY school_id, asmt_year
     ) s
  JOIN dim_inst_hier h ON h.school_id = s.school_id
ORDER BY district_name, school_name, asmt_year;

