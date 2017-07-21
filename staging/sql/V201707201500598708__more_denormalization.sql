# add code to math_practice

USE ${schemaName};

ALTER TABLE staging_exam ADD COLUMN available_accommodation_codes VARCHAR(500);

ALTER TABLE staging_math_practice ADD COLUMN code VARCHAR(4) NOT NULL;
