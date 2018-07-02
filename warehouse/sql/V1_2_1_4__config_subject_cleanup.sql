-- Remove unused columns
use ${schemaName};

ALTER TABLE depth_of_knowledge
    DROP COLUMN description;

ALTER TABLE claim
    DROP COLUMN name,
    DROP COLUMN description;

ALTER TABLE common_core_standard
    DROP COLUMN description;

ALTER TABLE subject_claim_score
    DROP COLUMN name;

ALTER TABLE target
    DROP COLUMN code,
    DROP COLUMN description,
    MODIFY COLUMN natural_id varchar(20) not null;

ALTER TABLE asmt_type
    DROP COLUMN name;

