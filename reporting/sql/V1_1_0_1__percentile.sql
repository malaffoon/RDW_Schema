-- Add support for percentile

USE ${schemaName};

CREATE TABLE percentile (
  id INT NOT NULL PRIMARY KEY,
  asmt_id INT NOT NULL,
  count INT NOT NULL,
  mean FLOAT NOT NULL,
  standard_deviation FLOAT NULL,
  update_import_id BIGINT NOT NULL,
  updated TIMESTAMP(6) NOT NULL,
  migrate_id BIGINT NOT NULL,
  CONSTRAINT fk__percentile__asmt FOREIGN KEY (asmt_id) REFERENCES asmt (id)
);

CREATE TABLE percentile_score (
  percentile_id INT NOT NULL,
  percent TINYINT NOT NULL,
  min_score SMALLINT NOT NULL,
  max_score SMALLINT NOT NULL,
  PRIMARY KEY (percentile_id, percent),
  CONSTRAINT fk__percentile_score__percentile FOREIGN KEY (percentile_id) REFERENCES percentile (id)
);

CREATE TABLE staging_percentile (
  id INT NOT NULL PRIMARY KEY,
  asmt_id INT NOT NULL,
  count INT NOT NULL,
  mean FLOAT NOT NULL,
  standard_deviation FLOAT NULL,
  update_import_id BIGINT NOT NULL,
  updated TIMESTAMP(6) NOT NULL,
  migrate_id BIGINT NOT NULL,
  deleted TINYINT NOT NULL
);

CREATE TABLE staging_percentile_score (
  percentile_id INT NOT NULL,
  percent TINYINT NOT NULL,
  min_score SMALLINT NOT NULL,
  max_score SMALLINT NOT NULL,
  PRIMARY KEY (percentile_id, percent)
);