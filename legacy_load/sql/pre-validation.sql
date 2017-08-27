set SEARCH_PATH to ca;

CREATE TABLE IF NOT EXISTS ca.pre_validation
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

-- TODO: this is an asmt that was not loaded into prod yet
CREATE TABLE IF NOT EXISTS ca.exclude_asmt
(
  guid varchar(1000)
);

INSERT INTO ca.exclude_asmt VALUES
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
insert into pre_validation select 1, 'total_ica';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*)
  FROM fact_asmt_outcome_vw f
  WHERE rec_status = 'C' and asmt_guid not in (select * from exclude_asmt);
-- select count(*) from exam where type_id = 1;

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total_iab';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*)
  FROM fact_block_asmt_outcome
  WHERE rec_status = 'C' and asmt_guid not in (select * from exclude_asmt);
-- select count(*) from exam where type_id = 2;

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total ica score', 'total std err', 'total perf level';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    sum(asmt_score)                        AS total_score,
    sum(asmt_score_range_max - asmt_score) AS total_std_err,
    sum(asmt_perf_lvl)                     AS total_perf_level
  FROM fact_asmt_outcome_vw
  WHERE rec_status = 'C' AND asmt_guid NOT IN (SELECT * FROM exclude_asmt);
-- select sum(scale_score), sum(scale_score_std_err), sum(performance_level) from exam where type_id = 1;

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total iab score', 'total std err', 'total perf level';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
  sum(asmt_claim_1_score)                        AS total_score,
  sum(asmt_claim_1_score_range_max - asmt_claim_1_score) AS total_std_err,
  sum(asmt_claim_1_perf_lvl)                     AS total_perf_level
  FROM fact_block_asmt_outcome
WHERE rec_status = 'C' AND asmt_guid NOT IN (SELECT * FROM exclude_asmt);
-- select sum(scale_score), sum(scale_score_std_err), sum(performance_level) from exam where type_id = 2;

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'total students';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(DISTINCT student_id)
  FROM dim_student
  WHERE rec_status = 'C';
-- select count(*) from student;

-- Exam break down by asmt year, admin condition and complete
insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'ica exams', 'asmt', 'asmt year', 'admin condition', 'complete';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*),
    am.name,
    asmt_period_year,
    case when coalesce(f.administration_condition, '') = '' then 'Valid' else administration_condition end as ac,
    case when complete is null then 'f' else complete end as complete
  FROM fact_asmt_outcome_vw f join dim_asmt_guid_to_natural_id_mapping am on am.guid = f.asmt_guid join dim_asmt da on am.guid = da.asmt_guid
  WHERE f.rec_status = 'C' and da.rec_status = 'C'
  GROUP BY asmt_period_year, am.name, ac, complete
  ORDER BY  count(*);

-- select count(*),
--   a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- from exam e join asmt a on e.asmt_id = a.id
--   where a.type_id = 1
-- group by  a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- order by   count(*);

insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'iab exams', 'asmt', 'asmt year', 'admin condition', 'complete';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    count(*),
    am.name,
    asmt_period_year,
    case when coalesce(f.administration_condition, '') = '' then 'Valid' else administration_condition end as ac,
    case when complete is null then 'f' else complete end as complete
  FROM fact_block_asmt_outcome f join dim_asmt_guid_to_natural_id_mapping am on am.guid = f.asmt_guid join dim_asmt da on am.guid = da.asmt_guid
  WHERE f.rec_status = 'C' and da.rec_status = 'C' and f.asmt_guid not in (select * from exclude_asmt)
  GROUP BY asmt_period_year, am.name, ac, complete
  ORDER BY  count(*);

-- select count(*),
--   a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- from exam e join asmt a on e.asmt_id = a.id
--   where a.type_id = 2
-- group by  a.natural_id,
--   a.school_year,
--   administration_condition_code,
--   completeness_code
-- order by   count(*);

--   Exam breakdown by district and school
insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'ica exams', 'district', 'school';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    s.count,
    s.school_id,
    h.district_name,
    h.school_name
  FROM (
         SELECT
           count(*) as count,
           school_id
         FROM fact_asmt_outcome_vw
         WHERE rec_status = 'C'
         GROUP BY school_id
       ) s
    JOIN dim_inst_hier h ON h.school_id = s.school_id where h.rec_status = 'C'
  ORDER BY   s.count,
    school_id;

-- select  s.count,
--   sch.natural_id,
--   d.name,
--   sch.name
-- from (
--        SELECT
--          count(*) as count,
--          s.natural_id
--        FROM exam e
--          JOIN asmt a ON a.id = e.asmt_id
--          JOIN school s on s.id = e.school_id
--        WHERE a.type_id = 1
--        GROUP BY natural_id
--      ) s join school sch on sch.natural_id = s.natural_id join district d on d.id = sch.district_id
-- ORDER BY s.count,
--   natural_id;


insert into pre_validation select (select max(testNum) from pre_validation) + 1, 'iab exams', 'district', 'school';
INSERT INTO pre_validation
  SELECT (SELECT max(testNum) FROM pre_validation),
    s.count,
    s.school_id,
    h.district_name,
    h.school_name
  FROM (
         SELECT
           count(*) as count,
           school_id
         FROM fact_block_asmt_outcome f
         WHERE rec_status = 'C' and f.asmt_guid not in (select * from exclude_asmt)
         GROUP BY school_id
       ) s
    JOIN dim_inst_hier h ON h.school_id = s.school_id where h.rec_status = 'C'
  ORDER BY   s.count,
    school_id;

-- select  s.count,
--   sch.natural_id,
--   d.name,
--   sch.name
-- from (
--        SELECT
--          count(*) as count,
--          s.natural_id
--        FROM exam e
--          JOIN asmt a ON a.id = e.asmt_id
--          JOIN school s on s.id = e.school_id
--        WHERE a.type_id = 2
--        GROUP BY natural_id
--      ) s join school sch on sch.natural_id = s.natural_id join district d on d.id = sch.district_id
-- ORDER BY s.count,
--   natural_id;