/**
** 	Initial script for the SBAC Reporting Staging schema used during migration
**
**  This schema is intentionally light on indexes.
**  The only indexes included here are meant to support 'INSERT IGNORE' feature since it is used in the migrate scripts.
**/

ALTER DATABASE ${schemaName} CHARACTER SET utf8  COLLATE utf8_unicode_ci;

USE ${schemaName};

/** Code tables **/

CREATE TABLE IF NOT EXISTS staging_grade (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(2) NOT NULL,
  name varchar(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_completeness (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_administration_condition (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_ethnicity (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(120) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_gender (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_accommodation (
  id smallint NOT NULL PRIMARY KEY,
  code varchar(25) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_translation (
  label varchar(40) NOT NULL,
  namespace varchar(10) NOT NULL,
  language_code varchar(3) NOT NULL,
  label_code varchar(128) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_claim (
  id smallint NOT NULL PRIMARY KEY,
  subject_id tinyint NOT NULL,
  code varchar(10) NOT NULL,
  name varchar(250) NOT NULL,
  description varchar(250) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_target (
  id smallint NOT NULL PRIMARY KEY,
  claim_id smallint NOT NULL,
  code varchar(10) NOT NULL,
  description varchar(500) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_depth_of_knowledge (
  id tinyint NOT NULL PRIMARY KEY,
  level tinyint NOT NULL,
  subject_id tinyint NOT NULL,
  description varchar(100) NOT NULL,
  reference varchar(1000) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_math_practice (
  practice tinyint NOT NULL PRIMARY KEY,
  code VARCHAR(4) NOT NULL,
  description varchar(250) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_item_trait_score (
  id tinyint NOT NULL PRIMARY KEY,
  dimension varchar(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_common_core_standard (
  id smallint NOT NULL PRIMARY KEY,
  natural_id varchar(20) NOT NULL,
  subject_id tinyint NOT NULL,
  description varchar(1000) NOT NULL
);

/** School and District **/

CREATE TABLE IF NOT EXISTS staging_district (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_school (
  id int NOT NULL PRIMARY KEY,
  district_id int NOT NULL,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  import_id bigint NOT NULL,
  deleted tinyint NOT NULL,
  migrate_id bigint NOT NULL,
  updated TIMESTAMP(6) NOT NULL
);

/** Student **/

CREATE TABLE IF NOT EXISTS staging_student (
  id int NOT NULL PRIMARY KEY,
  ssid varchar(65) NOT NULL,
  last_or_surname varchar(60),
  first_name varchar(60),
  middle_name varchar(60),
  gender_id tinyint,
  first_entry_into_us_school_at date,
  lep_entry_at date,
  lep_exit_at date,
  birthday date,
  import_id bigint NOT NULL,
  deleted tinyint NOT NULL,
  migrate_id bigint NOT NULL,
  updated TIMESTAMP(6) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_student_ethnicity (
  ethnicity_id tinyint NOT NULL,
  student_id int NOT NULL,
  UNIQUE INDEX idx__staging_student_ethnicity (student_id, ethnicity_id) -- to support INSERT IGNORE
);

/** Student Group **/

CREATE TABLE IF NOT EXISTS staging_student_group (
  id int NOT NULL PRIMARY KEY,
  name varchar(255) NOT NULL,
  school_id int NOT NULL,
  school_year smallint NOT NULL,
  subject_id tinyint,
  active tinyint NOT NULL,
  creator varchar(250),
  created timestamp(6) NOT NULL,
  import_id bigint NOT NULL,
  deleted tinyint NOT NULL,
  migrate_id bigint NOT NULL,
  updated TIMESTAMP(6) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_student_group_membership (
  student_group_id int NOT NULL,
  student_id int NOT NULL,
  UNIQUE INDEX idx__staging_student_group_membership (student_id, student_group_id)
);

CREATE TABLE IF NOT EXISTS staging_user_student_group (
  student_group_id int NOT NULL,
  user_login varchar(255) NOT NULL,
  UNIQUE INDEX idx__staging_user_student_group (student_group_id, user_login)
);

/** Assessment Packages related data **/

CREATE TABLE IF NOT EXISTS staging_asmt (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(250) NOT NULL,
  grade_id tinyint NOT NULL,
  type_id tinyint NOT NULL,
  subject_id tinyint NOT NULL,
  school_year smallint NOT NULL,
  name varchar(250),
  label varchar(255),
  version varchar(30),
  import_id bigint NOT NULL,
  deleted tinyint NOT NULL,
  migrate_id bigint NOT NULL,
  updated TIMESTAMP(6) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_asmt_score (
  asmt_id int NOT NULL PRIMARY KEY,
  cut_point_1 smallint,
  cut_point_2 smallint NOT NULL,
  cut_point_3 smallint,
  min_score smallint NOT NULL,
  max_score smallint NOT NULL,
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_item (
  id int NOT NULL PRIMARY KEY,
  claim_id smallint,
  target_id smallint,
  natural_id varchar(40) NOT NULL,
  asmt_id int NOT NULL,
  math_practice tinyint,
  allow_calc tinyint,
  dok_id tinyint NOT NULL,
  difficulty_code varchar(1) NOT NULL,
  max_points tinyint UNSIGNED NOT NULL,
  position smallint,
  migrate_id bigint NOT NULL,
  common_core_standard_ids varchar(200)
);

CREATE TABLE IF NOT EXISTS staging_item_other_target (
  item_id int NOT NULL,
  target_id smallint NOT NULL,
  UNIQUE INDEX idx_staging_item_other_target (item_id, target_id)
);

CREATE TABLE IF NOT EXISTS staging_item_common_core_standard (
  item_id int NOT NULL,
  common_core_standard_id smallint NOT NULL,
  UNIQUE INDEX idx__staging_item_common_core_standard (item_id, common_core_standard_id)
);

/** Exams **/

CREATE TABLE IF NOT EXISTS staging_exam_student (
  id bigint NOT NULL PRIMARY KEY,
  grade_id tinyint NOT NULL,
  student_id int NOT NULL,
  school_id int NOT NULL,
  iep tinyint NOT NULL,
  lep tinyint NOT NULL,
  section504 tinyint,
  economic_disadvantage tinyint NOT NULL,
  migrant_status tinyint,
  eng_prof_lvl varchar(20),
  t3_program_type varchar(20),
  language_code varchar(3),
  prim_disability_type varchar(3),
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_exam (
  id bigint NOT NULL PRIMARY KEY,
  type_id tinyint NOT NULL,
  exam_student_id bigint NOT NULL,
  school_year smallint NOT NULL,
  asmt_id int NOT NULL,
  asmt_version varchar(30),
  opportunity int,
  completeness_id tinyint NOT NULL,
  administration_condition_id tinyint NOT NULL,
  session_id varchar(128) NOT NULL,
  scale_score smallint,
  scale_score_std_err float,
  performance_level tinyint,
  completed_at timestamp(0) NOT NULL,
  import_id bigint NOT NULL,
  deleted tinyint NOT NULL,
  migrate_id bigint NOT NULL,
  updated TIMESTAMP(6) NOT NULL
 );

CREATE TABLE IF NOT EXISTS staging_exam_item (
  id bigint NOT NULL PRIMARY KEY,
  exam_id bigint NOT NULL,
  item_id int NOT NULL,
  score tinyint NOT NULL,
  score_status varchar(50),
  position smallint NOT NULL,
  response text,
  trait_evidence_elaboration_score tinyint,
  trait_evidence_elaboration_score_status varchar(50),
  trait_organization_purpose_score tinyint,
  trait_organization_purpose_score_status varchar(50),
  trait_conventions_score tinyint,
  trait_conventions_score_status varchar(50),
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_exam_available_accommodation (
  exam_id bigint NOT NULL,
  accommodation_id smallint NOT NULL,
  UNIQUE INDEX idx__staging_exam_available_accommodation (exam_id, accommodation_id)
);

CREATE TABLE IF NOT EXISTS staging_exam_claim_score (
  id bigint NOT NULL PRIMARY KEY,
  exam_id bigint NOT NULL,
  subject_claim_score_id smallint NOT NULL,
  scale_score smallint,
  scale_score_std_err float,
  category tinyint
);