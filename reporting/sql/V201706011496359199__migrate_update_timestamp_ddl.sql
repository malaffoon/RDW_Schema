/**
* change migrate update column to be refreshed on update
**/

USE ${schemaName};

ALTER TABLE migrate MODIFY COLUMN updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);