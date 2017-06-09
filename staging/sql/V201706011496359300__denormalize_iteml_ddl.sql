/**
* DWR-397 Denormalize/calculate item data during asmt package loading
**/

USE ${schemaName};

DROP TABLE staging_item_difficulty_cuts;

ALTER TABLE staging_item DROP COLUMN difficulty;
ALTER TABLE staging_item ADD COLUMN difficulty_code varchar(1) NOT NULL;
ALTER TABLE staging_item ADD COLUMN common_core_standard_ids varchar(200);

