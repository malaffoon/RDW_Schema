-- Add table to hold excluded target
USE ${schemaName};

-- A configuration table to hold targets to be excluded from the 'Target Report`.
-- This table is assumed to be manually updated.
-- Note that it is required to trigger a 'PACKAGE' content migrate in order for this data
-- to be migrated into reporting data marts.
CREATE TABLE asmt_target_exclusion (
  asmt_id int NOT NULL,
  target_id smallint NOT NULL,
  PRIMARY KEY(asmt_id, target_id),
  INDEX idx__asmt_target__target (target_id),
  CONSTRAINT fk__asmt_target__asmt FOREIGN KEY(asmt_id) REFERENCES asmt(id),
  CONSTRAINT fk__asmt_target__target FOREIGN KEY(target_id) REFERENCES target(id)
);