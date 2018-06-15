-- make student related data elements optional
use ${schemaName};

ALTER TABLE exam
    MODIFY COLUMN iep TINYINT NULL,
    MODIFY COLUMN economic_disadvantage TINYINT NULL;

ALTER TABLE audit_exam
    MODIFY COLUMN iep TINYINT NULL,
    MODIFY COLUMN economic_disadvantage TINYINT NULL;