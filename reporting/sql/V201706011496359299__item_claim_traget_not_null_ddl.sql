/**
* change migrate update column to be refreshed on update
**/

USE ${schemaName};

ALTER TABLE item MODIFY COLUMN claim_id smallint NOT NULL;
ALTER TABLE item MODIFY COLUMN target_id smallint NOT NULL;