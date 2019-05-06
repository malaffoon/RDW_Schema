-- Adds pipeline, pipeline script and pipeline test tables used for managing ingest pipeline transformations

use ${schemaName};

CREATE TABLE IF NOT EXISTS pipeline (
  id tinyint NOT NULL PRIMARY KEY,
  code varchar(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS pipeline_script (
  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pipeline_id tinyint NOT NULL,
  body text NOT NULL,
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  updated_by varchar(255) NOT NULL,
  INDEX idx__pipeline_script__pipeline_id (pipeline_id),
  CONSTRAINT fk__pipeline_script__pipeline_id FOREIGN KEY (pipeline_id) REFERENCES pipeline(id)
);

CREATE TABLE IF NOT EXISTS pipeline_test (
  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pipeline_id tinyint NOT NULL,
  name text,
  example_input text NOT NULL,
  expected_output text NOT NULL,
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  updated_by varchar(255) NOT NULL,
  INDEX idx__pipeline_test__pipeline_id (pipeline_id),
  CONSTRAINT fk__pipeline_test__pipeline_id FOREIGN KEY (pipeline_id) REFERENCES pipeline(id)
);

INSERT INTO pipeline (id, code) VALUES
  (1, 'exam'),
  (2, 'group'),
  (3, 'assessment');
