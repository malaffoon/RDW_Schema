/**
** cut points 1 and 3 are optional for iab
**/

USE ${schemaName};

ALTER TABLE asmt_score MODIFY COLUMN cut_point_1 smallint;
ALTER TABLE asmt_score MODIFY COLUMN cut_point_3 smallint;
