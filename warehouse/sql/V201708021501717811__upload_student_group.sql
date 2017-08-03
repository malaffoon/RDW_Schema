-- create tables for student groups upload management

USE ${schemaName};

CREATE TABLE IF NOT EXISTS upload_student_group_status (
  id tinyint NOT NULL PRIMARY KEY,
  name varchar(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS upload_student_group_batch (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  digest varchar(32) NOT NULL,
  status tinyint NOT NULL,
  creator varchar(250),
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  message text,
  INDEX idx__upload_student_group_batch__digest (digest)
);

CREATE TABLE IF NOT EXISTS upload_student_group (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  batch_id bigint NOT NULL,
  name varchar(255) NOT NULL,
  group_id int,
  school_natural_id varchar(40) NOT NULL,
  school_id int,
  school_year smallint NOT NULL,
  subject_code varchar(10),
  subject_id tinyint,
  student_ssid varchar(65),
  student_id bigint,
  group_user_login varchar(255),
  creator varchar(250),
  import_id bigint
);

CREATE TABLE IF NOT EXISTS upload_student_group_batch_progress (
  batch_it bigint,
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  message varchar(256)
);

CREATE TABLE IF NOT EXISTS upload_student_group_import_ref_type (
  id tinyint NOT NULL PRIMARY KEY,
  name varchar(100) NOT NULL UNIQUE
);

INSERT INTO upload_student_group_import_ref_type (id, name) VALUES
  (0, 'STUDENT_RESTORE_DELETED'),
  (1, 'STUDENT_NEW'),
  (2, 'STUDENT_GROUP_NEW'),
  (3, 'STUDENT_GROUP_MEMBERSHIP'),
  (4, 'STUDENT_GROUP_USER'),
  (5, 'STUDENT_GROUP_UPDATE');
  
CREATE TABLE IF NOT EXISTS upload_student_group_import (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  batch_id  bigint NOT NULL,
  school_id int,
  import_id bigint,
  ref varchar(255) NOT NULL, -- either a student ssid or group name, use this along with the unique index below to de-dupe
  ref_type tinyint,
  UNIQUE INDEX idx__upload_student_group_import__batch_ref (batch_id, ref_type)
);
