USE ${schemaName};

CREATE TABLE IF NOT EXISTS embargo_scope (
  id int NOT NULL PRIMARY KEY,
  code varchar(32)
);

INSERT INTO embargo_scope (id, code) VALUES
  (1, 'individual'),
  (2, 'aggregate');

CREATE TABLE IF NOT EXISTS district_embargo (
  district_id int NOT NULL,
  embargo_scope_id int NOT NULL,
  school_year smallint NOT NULL,
  enabled tinyint NOT NULL,
  updated TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) NOT NULL,
  updated_by varchar(255),
  PRIMARY KEY(district_id, embargo_scope_id, school_year),
  INDEX idx__district_embargo__district (district_id),
  INDEX idx__district_embargo__embargo_scope (embargo_scope_id),
  CONSTRAINT fk__district_embargo__district FOREIGN KEY (district_id) REFERENCES district(id) ON DELETE CASCADE,
  CONSTRAINT fk__district_embargo__embargo_scope FOREIGN KEY (embargo_scope_id) REFERENCES embargo_scope(id)
);

CREATE TABLE IF NOT EXISTS state_embargo (
  embargo_scope_id int NOT NULL,
  school_year smallint NOT NULL,
  enabled tinyint NOT NULL,
  updated TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) NOT NULL,
  updated_by varchar(255),
  PRIMARY KEY(embargo_scope_id, school_year),
  INDEX idx__state_embargo__embargo_scope (embargo_scope_id),
  CONSTRAINT fk__state_embargo__embargo_scope FOREIGN KEY (embargo_scope_id) REFERENCES embargo_scope(id)
);