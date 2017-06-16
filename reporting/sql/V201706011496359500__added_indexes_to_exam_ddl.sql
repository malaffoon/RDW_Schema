/**
* Add a few indexes to exam
**/

USE ${schemaName};

CREATE INDEX idx__exam__asmt_school_year ON exam (asmt_id, school_id, school_year);
CREATE INDEX idx__exam__school_grade ON exam (school_id, grade_id);

-- When adding an index that has the first column from a FOREIGN KEY CONSTRAINT, mySQL drops the FK index
-- This index seems to still improve performance of some queries, so I am adding it back.
CREATE INDEX fk__exam__school ON exam (school_id);
