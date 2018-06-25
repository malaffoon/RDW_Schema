use ${schemaName};

-- add up to 5 cut points
ALTER TABLE asmt_score
 -- allow nulls
 MODIFY COLUMN cut_point_2 smallint,
 ADD COLUMN cut_point_4 smallint,
 ADD COLUMN cut_point_5 smallint;

ALTER TABLE staging_asmt_score
-- allow nulls
 MODIFY COLUMN cut_point_2 smallint,
 ADD COLUMN cut_point_4 smallint,
 ADD COLUMN cut_point_5 smallint;

ALTER TABLE asmt
 -- allow nulls
 MODIFY COLUMN cut_point_2 smallint,
 ADD COLUMN cut_point_4 smallint,
 ADD COLUMN cut_point_5 smallint;