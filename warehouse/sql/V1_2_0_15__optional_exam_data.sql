-- make exam related data elements optional
use ${schemaName};

ALTER TABLE exam
    MODIFY COLUMN completeness_id tinyint null,
    MODIFY COLUMN administration_condition_id tinyint null,
    MODIFY COLUMN session_id varchar(128) null;

ALTER TABLE audit_exam
    MODIFY COLUMN completeness_id tinyint null,
    MODIFY COLUMN administration_condition_id tinyint null,
    MODIFY COLUMN session_id varchar(128) null;

ALTER TABLE exam_item
    MODIFY COLUMN score float null,
    MODIFY COLUMN position smallint null;

ALTER TABLE audit_exam_item
    MODIFY COLUMN score float null,
    MODIFY COLUMN position smallint null;

