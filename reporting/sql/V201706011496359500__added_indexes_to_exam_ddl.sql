/**
* Add a few indexes to exam
**/

USE ${schemaName};

CREATE INDEX idx__exam__asmt_school_year ON exam (asmt_id, school_id, school_year);
CREATE INDEX idx__exam__school_grade ON exam (school_id, grade_id);

