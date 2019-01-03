-- Adjust default school years
--
-- The default years were 2015, 2016, 2017, 2018.
-- Add 2019 and then remove older values. Ignore any failures due to constraint
-- violations, since real systems may have real data using the years.
--
-- Don't trigger a migration; deleted school_years don't migrate well.

USE ${schemaName};

DELETE IGNORE FROM school_year WHERE year in (2015, 2016);
INSERT IGNORE INTO school_year (year) VALUES (2019);
