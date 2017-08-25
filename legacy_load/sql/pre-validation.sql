set SEARCH_PATH to edware_ca;

create table pre_validation
(
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

insert into pre_validation select 1, 'total_ica';
insert into pre_validation select (select max(testNum) from pre_validation), count(*)  from fact_asmt_outcome_vw where rec_status = 'C';

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total_iab';
insert into pre_validation select (select max(testNum) from pre_validation), count(*) from fact_block_asmt_outcome where rec_status = 'C';

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total ica score', 'total std err', 'total perf level';
insert into pre_validation select (select max(testNum) from pre_validation),
  sum(asmt_score)                        AS total_score,
  sum(asmt_score_range_max - asmt_score) AS total_std_err,
  sum(asmt_perf_lvl)                     AS total_perf_level
FROM fact_asmt_outcome_vw
WHERE rec_status = 'C';


insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total students';
insert into pre_validation select (select max(testNum) from pre_validation), count(distinct student_id) from dim_student where rec_status = 'C';

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total students with ica exams';
insert into pre_validation select (select max(testNum) from pre_validation), count(distinct student_id) from fact_asmt_outcome_vw where rec_status = 'C';

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total students with iab exams';
insert into pre_validation select (select max(testNum) from pre_validation), count(distinct student_id) from fact_block_asmt_outcome where rec_status = 'C';

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'ica exams', 'asmt', 'asmt year', 'admin condition', 'complete';
insert into pre_validation select (select max(testNum) from pre_validation),
  count(*),
  asmt_guid,
  asmt_year,
  administration_condition,
  complete
FROM fact_asmt_outcome_vw
WHERE rec_status = 'C'
GROUP BY asmt_guid, asmt_year, administration_condition, complete
ORDER BY asmt_year, asmt_guid,administration_condition, complete;

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'iab exams', 'asmt', 'asmt year', 'admin condition', 'complete';
insert into pre_validation select (select max(testNum) from pre_validation),
  count(*),
  asmt_guid,
  asmt_year,
  administration_condition,
  complete
FROM fact_block_asmt_outcome
WHERE rec_status = 'C'
GROUP BY asmt_guid, asmt_year, administration_condition, complete
ORDER BY asmt_year, asmt_guid,administration_condition, complete;

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'ica exams', 'district', 'school';
insert into pre_validation select (select max(testNum) from pre_validation),
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

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'iab exams', 'district', 'school';
insert into pre_validation select (select max(testNum) from pre_validation),
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

