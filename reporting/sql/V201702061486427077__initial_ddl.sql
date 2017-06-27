/**
** 	Initial script for the SBAC Reporting Data Warehouse schema
**
**  NOTES
**  This schema assumes the following:
**     1. one state (aka tenant) per data warehouse
**     2. not all data elements from TRT are included, only those that are required for the current reporting
**     3. MySQL treats FK this way:
**           In the referencing table, there must be an index where the foreign key columns are listed as the first columns in the same order.
**           Such an index is created on the referencing table automatically if it does not exist.
**           This index is silently dropped later, if you create another index that can be used to enforce the foreign key constraint.
**           When restoring a DB from a back up, MySQL does not see an automatically created FK index as such and treats it as a user defined.
**           So when running this on the restored DB, you will end up with duplicate indexes.
**      To avoid this problem we explicitly create all the indexes.
**/

ALTER DATABASE ${schemaName} CHARACTER SET utf8 COLLATE utf8_unicode_ci;

USE ${schemaName};

/** Migrate **/

CREATE TABLE IF NOT EXISTS migrate_status (
  id tinyint NOT NULL PRIMARY KEY,
  name varchar(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS migrate (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  job_id bigint NOT NULL,
  status tinyint NOT NULL,
  first_import_id bigint NOT NULL,
  last_import_id bigint NOT NULL,
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  message text
 );

/** Reference tables **/

CREATE TABLE IF NOT EXISTS subject (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(10) NOT NULL UNIQUE
 );

CREATE TABLE IF NOT EXISTS grade (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(2)  NOT NULL UNIQUE,
  name varchar(100) NOT NULL UNIQUE
 );

CREATE TABLE IF NOT EXISTS asmt_type (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(10) NOT NULL UNIQUE,
  name varchar(24) NOT NULL UNIQUE
 );

CREATE TABLE IF NOT EXISTS completeness (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(10) NOT NULL UNIQUE
 );

CREATE TABLE IF NOT EXISTS administration_condition (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(20) NOT NULL UNIQUE
 );

CREATE TABLE IF NOT EXISTS ethnicity (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(120) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS gender (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(80) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS accommodation (
  id smallint NOT NULL PRIMARY KEY,
  code varchar(25) NOT NULL UNIQUE
);

/** Accommodation Translations **/

CREATE TABLE IF NOT EXISTS translation (
  label varchar(40) NOT NULL,
  label_code varchar(128) NOT NULL,
  namespace varchar(10) NOT NULL,
  language_code varchar(3) NOT NULL,
  UNIQUE INDEX idx__translation__namespace_label_code_language_code (namespace, label_code, language_code)
);

/** Assessment Packages related data **/

CREATE TABLE IF NOT EXISTS asmt (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(250) NOT NULL,
  grade_id tinyint NOT NULL,
  type_id tinyint NOT NULL,
  subject_id tinyint NOT NULL,
  school_year smallint NOT NULL,
  name varchar(250) NOT NULL,
  label varchar(255) NOT NULL,
  version varchar(30),
  import_id bigint NOT NULL,
  claim1_score_code varchar(10),
  claim2_score_code varchar(10),
  claim3_score_code varchar(10),
  claim4_score_code varchar(10),
  cut_point_1 smallint,
  cut_point_2 smallint NOT NULL,
  cut_point_3 smallint,
  min_score smallint NOT NULL,
  max_score smallint NOT NULL,
  UNIQUE INDEX idx__asmt__natural_id (natural_id),
  INDEX idx__asmt__grade (grade_id),
  INDEX idx__asmt__type (type_id),
  INDEX idx__asmt__subject (subject_id),
  CONSTRAINT fk__asmt__grade FOREIGN KEY (grade_id) REFERENCES grade(id),
  CONSTRAINT fk__asmt__type FOREIGN KEY (type_id) REFERENCES asmt_type(id),
  CONSTRAINT fk__asmt__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);

CREATE TABLE IF NOT EXISTS asmt_score (
  asmt_id int NOT NULL PRIMARY KEY,
  cut_point_1 smallint,
  cut_point_2 smallint NOT NULL,
  cut_point_3 smallint,
  min_score smallint NOT NULL,
  max_score smallint NOT NULL,
  UNIQUE INDEX idx__asmt_score__asmt (asmt_id),
  CONSTRAINT fk__asmt_score__asmt FOREIGN KEY (asmt_id) REFERENCES asmt(id)
);

CREATE TABLE IF NOT EXISTS claim (
  id smallint NOT NULL PRIMARY KEY,
  subject_id tinyint NOT NULL,
  code varchar(10) NOT NULL,
  name varchar(250) NOT NULL,
  description varchar(250) NOT NULL,
  INDEX idx__claim__subject (subject_id),
  CONSTRAINT fk__claim__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);

CREATE TABLE IF NOT EXISTS subject_claim_score (
  id tinyint NOT NULL PRIMARY KEY,
  subject_id tinyint NOT NULL,
  asmt_type_id tinyint NOT NULL,
  code varchar(10) NOT NULL,
  name varchar(250) NOT NULL,
  INDEX idx__subject_claim_score__subject (subject_id),
  INDEX idx__subject_claim_score__asmt_type (asmt_type_id),
  CONSTRAINT fk__subject_claim_score__subject FOREIGN KEY (subject_id) REFERENCES subject(id),
  CONSTRAINT fk__subject_claim_score__asmt_type FOREIGN KEY (asmt_type_id) REFERENCES asmt_type(id)
);

CREATE TABLE IF NOT EXISTS target (
  id smallint NOT NULL PRIMARY KEY,
  claim_id smallint NOT NULL,
  code varchar(10) NOT NULL,
  description varchar(500) NOT NULL,
  INDEX idx__target__claim (claim_id),
  CONSTRAINT fk__target__claim FOREIGN KEY (claim_id) REFERENCES claim(id)
);

CREATE TABLE IF NOT EXISTS common_core_standard (
  id smallint NOT NULL PRIMARY KEY,
  natural_id varchar(20) NOT NULL,
  subject_id tinyint NOT NULL,
  description varchar(1000) NOT NULL,
  INDEX idx__common_core_standard__subject (subject_id),
  CONSTRAINT fk__common_core_standard__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);

CREATE TABLE IF NOT EXISTS depth_of_knowledge (
  id tinyint NOT NULL PRIMARY KEY,
  level tinyint NOT NULL,
  subject_id tinyint NOT NULL,
  description varchar(100) NOT NULL,
  reference varchar(1000) NOT NULL,
  INDEX idx__depth_of_knowledge__subject (subject_id),
  CONSTRAINT fk__depth_of_knowledge__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);

CREATE TABLE IF NOT EXISTS math_practice (
  practice tinyint NOT NULL PRIMARY KEY,
  description varchar(250) NOT NULL
);

CREATE TABLE IF NOT EXISTS item (
  id int NOT NULL PRIMARY KEY,
  claim_id smallint NOT NULL,
  target_id smallint NOT NULL,
  natural_id varchar(40) NOT NULL,
  asmt_id int NOT NULL,
  math_practice tinyint,
  allow_calc tinyint,
  dok_id tinyint NOT NULL,
  difficulty_code varchar(1) NOT NULL,
  max_points tinyint UNSIGNED NOT NULL,
  position tinyint,
  claim_code varchar(10) NOT NULL,
  target_code varchar(10) NOT NULL,
  common_core_standard_ids varchar(200),
  UNIQUE INDEX idx__item__asmt_natural_id (asmt_id, natural_id),
  INDEX idx__item__claim (claim_id),
  INDEX idx__item__target (target_id),
  INDEX idx__item__math_practice (math_practice),
  INDEX idx__item__dok (dok_id),
  CONSTRAINT fk__item__asmt FOREIGN KEY (asmt_id) REFERENCES asmt(id),
  CONSTRAINT fk__item__claim FOREIGN KEY (claim_id) REFERENCES claim(id),
  CONSTRAINT fk__item__target FOREIGN KEY (target_id) REFERENCES target(id),
  CONSTRAINT fk__item__math_practice FOREIGN KEY (math_practice) REFERENCES math_practice(practice),
  CONSTRAINT fk__item__dok FOREIGN KEY (dok_id) REFERENCES depth_of_knowledge(id)
);

CREATE TABLE IF NOT EXISTS item_other_target (
  item_id int NOT NULL,
  target_id smallint NOT NULL,
  UNIQUE INDEX idx__item_other_target (item_id, target_id),
  INDEX idx__item_other_target__target (target_id),
  CONSTRAINT fk__item_target__item FOREIGN KEY (item_id) REFERENCES item(id),
  CONSTRAINT fk__item_target__target FOREIGN KEY (target_id) REFERENCES target(id)
);

CREATE TABLE IF NOT EXISTS item_common_core_standard (
  item_id int NOT NULL,
  common_core_standard_id smallint NOT NULL,
  UNIQUE INDEX idx__item_common_core_standard (item_id, common_core_standard_id),
  INDEX idx__item_common_core_standard__common_core_standard (common_core_standard_id),
  CONSTRAINT fk__item_common_core_standard__item FOREIGN KEY (item_id) REFERENCES item(id),
  CONSTRAINT fk__item_common_core_standard__common_core_standard FOREIGN KEY (common_core_standard_id) REFERENCES common_core_standard(id)
);

CREATE TABLE IF NOT EXISTS item_trait_score (
  id tinyint NOT NULL PRIMARY KEY,
  dimension varchar(100) NOT NULL,
  UNIQUE INDEX idx__item_trait_score__dimension (dimension)
 );

/** Data derived from the exams delivered via TRT **/

CREATE TABLE IF NOT EXISTS district (
  id int NOT NULL PRIMARY KEY,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  UNIQUE INDEX idx__district__natural_id (natural_id)
);

CREATE TABLE IF NOT EXISTS school (
  id int NOT NULL PRIMARY KEY,
  district_id int NOT NULL,
  natural_id varchar(40) NOT NULL,
  name varchar(100) NOT NULL,
  import_id bigint NOT NULL,
  UNIQUE INDEX idx__school__natural_id (natural_id),
  INDEX idx__school__district (district_id),
  CONSTRAINT fk__school__district FOREIGN KEY (district_id) REFERENCES district(id)
);

/** Student Groups */

CREATE TABLE IF NOT EXISTS student (
  id int NOT NULL PRIMARY KEY,
  ssid varchar(65) NOT NULL,
  last_or_surname varchar(60),
  first_name varchar(60),
  middle_name varchar(60),
  gender_id tinyint, -- intentionally not constrained since it is denormalized
  gender_code varchar(80),
  first_entry_into_us_school_at date,
  lep_entry_at date,
  lep_exit_at date,
  birthday date,
  import_id bigint NOT NULL,
  UNIQUE INDEX idx__student__ssid (ssid)
 );

CREATE TABLE IF NOT EXISTS student_ethnicity (
  ethnicity_id tinyint NOT NULL,
  ethnicity_code varchar(120) NOT NULL,
  student_id int NOT NULL,
  UNIQUE INDEX idx__student_ethnicity__student_ethnicity (student_id, ethnicity_id),
  INDEX idx__student_ethnicity__ethnicity (ethnicity_id),
  CONSTRAINT fk__student_ethnicity__student FOREIGN KEY (student_id) REFERENCES student(id),
  CONSTRAINT fk__student_ethnicity__ethnicity FOREIGN KEY (ethnicity_id) REFERENCES ethnicity(id)
);

-- Note: data mart has only active groups
CREATE TABLE IF NOT EXISTS student_group (
  id int NOT NULL PRIMARY KEY,
  name varchar(255) NOT NULL,
  school_id int NOT NULL,
  school_year smallint NOT NULL,
  subject_id tinyint,
  creator varchar(250),
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  import_id bigint NOT NULL,
  UNIQUE INDEX idx__student_group__school_name_year (school_id, name, school_year),
  INDEX idx__student_group__subject (subject_id),
  CONSTRAINT fk__student_group__school FOREIGN KEY (school_id) REFERENCES school(id),
  CONSTRAINT fk__student_group__subject FOREIGN KEY (subject_id) REFERENCES subject(id)
);

CREATE TABLE IF NOT EXISTS student_group_membership (
  student_group_id int NOT NULL,
  student_id int NOT NULL,
  UNIQUE INDEX idx__student_group_membership (student_group_id, student_id),
  INDEX idx_student_group_membership__student (student_id),
  CONSTRAINT fk__student_group_membership__student_group FOREIGN KEY (student_group_id) REFERENCES student_group(id),
  CONSTRAINT fk__student_group_membership__student FOREIGN KEY (student_id) REFERENCES student(id)
);

CREATE TABLE IF NOT EXISTS user_student_group (
  student_group_id int NOT NULL,
  user_login varchar(255) NOT NULL,
  UNIQUE INDEX idx__user_student_group (student_group_id, user_login),
  CONSTRAINT fk__user_student_group__student_group FOREIGN KEY (student_group_id) REFERENCES student_group(id)
);

/** Exams **/
CREATE TABLE IF NOT EXISTS exam (
  id bigint NOT NULL PRIMARY KEY,
  type_id tinyint NOT NULL,
  grade_id tinyint NOT NULL,  -- intentionally not constrained since it should be denormalized
  student_id int NOT NULL,
  school_id int NOT NULL,
  iep tinyint NOT NULL,
  lep tinyint NOT NULL,
  section504 tinyint NOT NULL,
  economic_disadvantage tinyint NOT NULL,
  migrant_status tinyint,
  eng_prof_lvl varchar(20),
  t3_program_type varchar(20),
  language_code varchar(3),
  prim_disability_type varchar(3),
  school_year smallint NOT NULL,
  asmt_id int NOT NULL,
  asmt_version varchar(30),
  opportunity int,
  completeness_id tinyint NOT NULL, -- intentionally not constrained since it is denormalized
  completeness_code varchar(10) NOT NULL,
  administration_condition_id tinyint NOT NULL,  -- intentionally not constrained since it is denormalized
  administration_condition_code varchar(20) NOT NULL,
  session_id varchar(128) NOT NULL,
  scale_score smallint,
  scale_score_std_err float,
  performance_level tinyint,
  claim1_scale_score smallint,
  claim1_scale_score_std_err float,
  claim1_category tinyint,
  claim2_scale_score smallint,
  claim2_scale_score_std_err float,
  claim2_category tinyint,
  claim3_scale_score smallint,
  claim3_scale_score_std_err float,
  claim3_category tinyint,
  claim4_scale_score smallint,
  claim4_scale_score_std_err float,
  claim4_category tinyint,
  completed_at timestamp(0) NOT NULL,
  import_id bigint NOT NULL,
  INDEX idx__exam__student (student_id),
  INDEX idx__exam__school (school_id),
  INDEX idx__exam__asmt_type (type_id),
  INDEX idx__exam__asmt_school_year (asmt_id, school_id, school_year),
  INDEX idx__exam__school_grade(school_id, grade_id),
  CONSTRAINT fk__exam__student FOREIGN KEY (student_id) REFERENCES student(id),
  CONSTRAINT fk__exam__school FOREIGN KEY (school_id) REFERENCES school(id),
  CONSTRAINT fk__exam__type FOREIGN KEY (type_id) REFERENCES asmt_type(id),
  CONSTRAINT fk__exam__asmt FOREIGN KEY (asmt_id) REFERENCES asmt(id)
);

CREATE TABLE IF NOT EXISTS exam_claim_score_mapping (
  subject_claim_score_id tinyint NOT NULL,
  num tinyint NOT NULL,
  UNIQUE INDEX idx__exam_claim_score_mapping (subject_claim_score_id, num),
  CONSTRAINT fk__exam_claim_score_mapping__subject_claim_score FOREIGN KEY (subject_claim_score_id) REFERENCES subject_claim_score(id)
);

CREATE TABLE IF NOT EXISTS exam_item (
  id bigint NOT NULL PRIMARY KEY,
  exam_id bigint NOT NULL,
  item_id int NOT NULL,
  score tinyint NOT NULL,
  score_status varchar(50),
  position int NOT NULL,
  response text,
  trait_evidence_elaboration_score tinyint,
  trait_evidence_elaboration_score_status varchar(50),
  trait_organization_purpose_score tinyint,
  trait_organization_purpose_score_status varchar(50),
  trait_conventions_score tinyint,
  trait_conventions_score_status varchar(50),
  INDEX idx__exam_item__exam (exam_id),
  INDEX idx__exam_item__item (item_id),
  CONSTRAINT fk__exam_item__exam FOREIGN KEY (exam_id) REFERENCES exam(id),
  CONSTRAINT fk__exam_item__item FOREIGN KEY (item_id) REFERENCES item(id)
);

CREATE TABLE IF NOT EXISTS exam_available_accommodation (
  exam_id bigint NOT NULL,
  accommodation_id smallint NOT NULL,
  UNIQUE INDEX idx__exam_available_accommodation (exam_id, accommodation_id),
  INDEX idx__exam_available_accommodation__accommodation (accommodation_id),
  CONSTRAINT fk__exam_available_accommodation__exam FOREIGN KEY (exam_id) REFERENCES exam(id),
  CONSTRAINT fk__exam_available_accommodation__accomodation FOREIGN KEY (accommodation_id) REFERENCES accommodation(id)
);