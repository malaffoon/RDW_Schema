-- Add support for percentile

USE ${schemaName};

CREATE TABLE percentile (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  asmt_id INT NOT NULL,
  count INT NOT NULL,
  mean FLOAT NOT NULL,
  standard_deviation FLOAT NULL,
  import_id BIGINT NOT NULL,
  update_import_id BIGINT NOT NULL,
  created TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT fk__percentile__asmt FOREIGN KEY (asmt_id) REFERENCES asmt (id)
);

CREATE TABLE percentile_score (
  percentile_id INT NOT NULL,
  percent TINYINT NOT NULL,
  score FLOAT NOT NULL,
  PRIMARY KEY (percentile_id, percent),
  CONSTRAINT fk__percentile_score__percentile FOREIGN KEY (percentile_id) REFERENCES percentile (id)
);

