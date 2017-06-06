/**
* change item primary claim and target to be not null
**/

USE ${schemaName};

-- please note that this is not instantenious, expect some delay..in seconds
UPDATE item i
  JOIN asmt a
SET
  i.claim_id = (select id from claim c where c.subject_id = a.subject_id limit 1),
  i.target_id = (select id from target t where t.claim_id = (select id from claim where subject_id = a.subject_id limit 1) limit 1) ;

ALTER TABLE item MODIFY COLUMN claim_id smallint NOT NULL;
ALTER TABLE item MODIFY COLUMN target_id smallint NOT NULL;