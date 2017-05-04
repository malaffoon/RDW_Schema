/**
** 	Initial script for the SBAC Reporting Staging schema used during migration
**/

ALTER DATABASE staging CHARACTER SET utf8  COLLATE utf8_unicode_ci;

USE staging;

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
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_student (
  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  ssid varchar(65) NOT NULL,
  last_or_surname varchar(60) NOT NULL,
  first_name varchar(60) NOT NULL,
  middle_name varchar(60),
  gender_id tinyint NOT NULL,
  first_entry_into_us_school_at date,
  lep_entry_at date,
  lep_exit_at date,
  birthday date NOT NULL,
  import_id bigint NOT NULL,
  deleted tinyint NOT NULL,
  migrate_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_student_ethnicity (
  id int NOT NULL PRIMARY KEY,
  ethnicity_id tinyint NOT NULL,
  student_id int NOT NULL
);
