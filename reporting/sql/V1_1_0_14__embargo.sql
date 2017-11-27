USE ${schemaName};

ALTER TABLE school
  ADD embargoed tinyint NOT NULL;

ALTER TABLE school_group
  ADD embargoed tinyint NOT NULL;

ALTER TABLE district
  ADD embargoed tinyint NOT NULL;