-- Changes to support target data migration
USE ${schemaName};

ALTER TABLE staging_target ADD natural_id varchar(20) NOT NULL;

CREATE TABLE staging_asmt_target_exclusion (
  asmt_id int NOT NULL,
  target_id smallint NOT NULL,
  migrate_id bigint NOT NULL
);

CREATE TABLE staging_asmt_target (
  asmt_id int NOT NULL,
  target_id smallint NOT NULL,
  migrate_id bigint NOT NULL
);

CREATE TABLE staging_exam_target_score (
  id bigint NOT NULL PRIMARY KEY,
  exam_id bigint NOT NULL,
  target_id smallint NOT NULL,
  student_relative_residual_score float,
  standard_met_relative_residual_score float
);