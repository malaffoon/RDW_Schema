use ${schemaName};

-- add up to 5 cut points
ALTER TABLE asmt_score
-- allow nulls
 MODIFY COLUMN cut_point_2 float,
 ADD COLUMN cut_point_4 float,
 ADD COLUMN cut_point_5 float;