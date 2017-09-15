/*
Redshift script for the SBAC Aggregate Reporting Data Warehouse 1.0.0 schema
*/

CREATE SCHEMA reporting;
SET client_encoding = 'UTF8';

-- staging tables
CREATE TABLE staging_subject (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(10) NOT NULL UNIQUE
);

CREATE TABLE staging_grade (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(2)  NOT NULL UNIQUE,
  name character varying(100) NOT NULL UNIQUE
);

CREATE TABLE staging_asmt_type (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(10) NOT NULL UNIQUE,
  name character varying(24) NOT NULL UNIQUE
);

CREATE TABLE staging_completeness (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(10) NOT NULL UNIQUE
);

CREATE TABLE staging_administration_condition (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(20) NOT NULL UNIQUE
);

CREATE TABLE staging_ethnicity (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(120) NOT NULL UNIQUE
);

CREATE TABLE staging_gender (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(80) NOT NULL UNIQUE
);

CREATE TABLE staging_school_year (
  year smallint NOT NULL PRIMARY KEY
);

CREATE TABLE staging_asmt (
  id int PRIMARY KEY NOT NULL,
  natural_id character varying(250) NOT NULL,
  grade_id smallint NOT NULL,
  type_id smallint NOT NULL,
  subject_id smallint NOT NULL,
  school_year smallint NOT NULL,
  name character varying(250) NOT NULL
 );

CREATE TABLE staging_subject_claim_score (
  id  smallint PRIMARY KEY   NOT NULL,
  subject_id   smallint NOT NULL,
  asmt_type_id smallint NOT NULL,
  code character varying(10) NOT NULL,
  name character varying(250) NOT NULL
);

CREATE TABLE staging_district (
  id int PRIMARY KEY NOT NULL,
  natural_id character varying(40) NOT NULL,
  name character varying(100) NOT NULL
);

CREATE TABLE staging_school (
  id int PRIMARY KEY NOT NULL,
  district_id int NOT NULL,
  natural_id character varying(40) NOT NULL,
  name character varying(100) NOT NULL
);

CREATE TABLE staging_student (
  id int PRIMARY KEY NOT NULL,
  ssid character varying(65) NOT NULL,
  last_or_surname character varying(60),
  first_name character varying(60),
  middle_name character varying(60),
  gender_id smallint
 );

CREATE TABLE staging_student_ethnicity (
  ethnicity_id smallint NOT NULL,
  student_id int NOT NULL
);

CREATE TABLE staging_exam_student (
  id bigint PRIMARY KEY NOT NULL,
  grade_id smallint NOT NULL,
  student_id int NOT NULL,
  school_id int NOT NULL,
  iep smallint NOT NULL,
  lep smallint NOT NULL,
  section504 smallint,
  economic_disadvantage smallint NOT NULL,
  migrant_status smallint,
 );

CREATE TABLE staging_exam (
  id bigint PRIMARY KEY NOT NULL,
  type_id smallint NOT NULL,
  exam_student_id bigint NOT NULL,
  school_year smallint NOT NULL,
  asmt_id int NOT NULL,
  completeness_id smallint NOT NULL,
  administration_condition_id smallint NOT NULL,
  scale_score float,
  scale_score_std_err float,
  performance_level smallint,
  completed_at  timestamp without time zone NOT NULL
);

CREATE TABLE staging_exam_claim_score (
  id bigint PRIMARY KEY NOT NULL,
  exam_id bigint NOT NULL,
  subject_claim_score_id smallint NOT NULL,
  scale_score float,
  scale_score_std_err float,
  category smallint
);

-- configuration

CREATE TABLE exam_claim_score_mapping (
  subject_claim_score_id smallint NOT NULL,
  num smallint NOT NULL
  );

-- TODO move to DML
INSERT INTO exam_claim_score_mapping (subject_claim_score_id, num) VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (4, 1),
  (5, 2),
  (6, 3),
  (7, 4),
  (8, 1),
  (9, 2),
  (10, 3),
  (11, 1),
  (12, 2),
  (13, 3),
  (14, 4);

-- dimensions

CREATE TABLE subject (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(10) NOT NULL UNIQUE
);

CREATE TABLE grade (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(2)  NOT NULL UNIQUE,
  name character varying(100) NOT NULL UNIQUE
);

CREATE TABLE asmt_type (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(10) NOT NULL UNIQUE,
  name character varying(24) NOT NULL UNIQUE
);

CREATE TABLE completeness (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(10) NOT NULL UNIQUE
);

CREATE TABLE administration_condition (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(20) NOT NULL UNIQUE
);

CREATE TABLE  district (
  id integer PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL
);

CREATE TABLE school (
  id integer PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  district_id integer NOT NULL
 );

CREATE TABLE ica_asmt (
  id bigint PRIMARY KEY,
  grade_id smallint NOT NULL,
  school_year int NOT NULL,
  subject_id smallint NOT NULL
);

CREATE TABLE iab_asmt (
  id bigint PRIMARY KEY,
  grade_id smallint NOT NULL,
  school_year int NOT NULL,
  subject_id smallint NOT NULL
);

CREATE TABLE gender (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(80) NOT NULL UNIQUE
);

CREATE TABLE ethnicity (
  id smallint NOT NULL PRIMARY KEY,
  code character varying(120) NOT NULL UNIQUE
);

CREATE TABLE student(
  id bigint PRIMARY KEY,
  gender_id int NOT NULL
 );

CREATE TABLE student_ethnicity (
  ethnicity_id smallint  NOT NULL,
  student_id int NOT NULL
);

-- facts

CREATE TABLE fact_student_ica_exam (
  id bigint PRIMARY KEY,
  district_id integer NOT NULL,
  school_id integer NOT NULL,
  student_id bigint NOT NULL,
  gender_id int NOT NULL,
  asmt_id bigint NOT NULL,
  asmt_grade_id smallint NOT NULL,
  grade_id smallint NOT NULL,
  school_year smallint NOT NULL,
  iep smallint NOT NULL,
  lep smallint NOT NULL,
  section504 smallint,
  economic_disadvantage smallint NOT NULL,
  migrant_status smallint,
  completeness_id smallint NOT NULL,
  administration_condition_id smallint NOT NULL,
  scale_score float,
  scale_score_std_err float,
  performance_level smallint,
  claim1_scale_score float,
  claim1_scale_score_std_err float,
  claim1_category smallint,
  claim2_scale_score float,
  claim2_scale_score_std_err float,
  claim2_category smallint,
  claim3_scale_score float,
  claim3_scale_score_std_err float,
  claim3_category smallint,
  claim4_scale_score float,
  claim4_scale_score_std_err float,
  claim4_category smallint
);

CREATE TABLE fact_student_iab_exam (
  id bigint PRIMARY KEY,
  district_id integer NOT NULL,
  school_id integer NOT NULL,
  student_id bigint NOT NULL,
  gender_id int NOT NULL,
  asmt_id bigint NOT NULL,
  asmt_grade_id smallint NOT NULL,
  grade_id smallint NOT NULL,
  school_year smallint NOT NULL,
  iep smallint NOT NULL,
  lep smallint NOT NULL,
  section504 smallint,
  economic_disadvantage smallint NOT NULL,
  migrant_status smallint,
  completeness_id smallint NOT NULL,
  administration_condition_id smallint NOT NULL,
  scale_score float,
  scale_score_std_err float,
  performance_level smallint
);
