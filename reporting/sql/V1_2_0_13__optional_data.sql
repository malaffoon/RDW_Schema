-- make some data elements optional
use ${schemaName};

ALTER TABLE exam
    MODIFY COLUMN iep TINYINT NULL,
    MODIFY COLUMN economic_disadvantage TINYINT NULL,
    MODIFY COLUMN completeness_code VARCHAR(10) NULL,
    MODIFY COLUMN administration_condition_code VARCHAR(20) NULL,
    MODIFY COLUMN session_id VARCHAR(128) NULL;

ALTER TABLE exam_item
    MODIFY COLUMN position SMALLINT NULL;

ALTER TABLE staging_exam
    MODIFY COLUMN completeness_id TINYINT NULL,
    MODIFY COLUMN administration_condition_id TINYINT NULL,
    MODIFY COLUMN session_id VARCHAR(128) NULL,
    MODIFY COLUMN iep TINYINT NULL,
    MODIFY COLUMN economic_disadvantage TINYINT NULL;

ALTER TABLE staging_exam_item
    MODIFY COLUMN score TINYINT NULL, -- during migrate process into `exam_item` NULL will be converted to -1
    MODIFY COLUMN position SMALLINT NULL;