USE ${schemaName};

ALTER TABLE school ADD district_embargo_enabled tinyint;
UPDATE school SET district_embargo_enabled = 0;
ALTER TABLE school MODIFY COLUMN district_embargo_enabled tinyint NOT NULL;

ALTER TABLE school_group ADD district_embargo_enabled tinyint;
UPDATE school_group SET district_embargo_enabled = 0;
ALTER TABLE school_group MODIFY COLUMN district_embargo_enabled tinyint NOT NULL;

ALTER TABLE district ADD embargo_enabled tinyint;
UPDATE district SET embargo_enabled = 0;
ALTER TABLE district MODIFY COLUMN embargo_enabled tinyint NOT NULL;