/**
* Rename claim column to be consistent with the names in the exam table
**/

USE ${schemaName};

ALTER TABLE asmt CHANGE COLUMN claim_1_score_code claim1_score_code varchar(10);
ALTER TABLE asmt CHANGE COLUMN claim_2_score_code claim2_score_code varchar(10);
ALTER TABLE asmt CHANGE COLUMN claim_3_score_code claim3_score_code varchar(10);
ALTER TABLE asmt CHANGE COLUMN claim_4_score_code claim4_score_code varchar(10);