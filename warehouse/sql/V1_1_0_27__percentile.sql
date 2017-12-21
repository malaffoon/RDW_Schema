-- Add support for percentile

USE ${schemaName};

CREATE TABLE percentile (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  asmt_id INT NOT NULL,
  number INT NOT NULL,
  mean FLOAT NOT NULL,
  standard_deviation FLOAT NULL,
  import_id BIGINT NOT NULL,
  update_import_id BIGINT NOT NULL,
  created TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  updated TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  CONSTRAINT fk__percentile__asmt
    FOREIGN KEY (asmt_id) REFERENCES asmt (id)
);

CREATE TABLE percentile_score (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  percentile_id INT NOT NULL,
  percent TINYINT NOT NULL,
  score INT NOT NULL,
  min INT NOT NULL,
  max INT NOT NULL
);

