# remove available_accommodation_codes from exam in staging

USE ${schemaName};

ALTER TABLE staging_exam DROP COLUMN available_accommodation_codes;

