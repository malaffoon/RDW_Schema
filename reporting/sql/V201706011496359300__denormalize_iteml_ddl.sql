/**
* DWR-397 Denormalize/calculate item data during asmt package loading
**/

USE ${schemaName};

-- replace difficulty number with the translated level
ALTER TABLE item ADD COLUMN difficulty_code varchar(1);
update item i
  join asmt a on i.asmt_id = a.id
  join item_difficulty_cuts c on c.asmt_type_id = a.type_id and a.subject_id = c.subject_id and a.grade_id = c.grade_id
set
  i.difficulty_code = if(i.difficulty < c.moderate_low_end, 'L', if(i.difficulty < c.difficult_low_end, 'M', 'D' ));


ALTER TABLE item MODIFY COLUMN  difficulty_code varchar(1) NOT NULL;
ALTER TABLE item DROP COLUMN difficulty;

DROP TABLE item_difficulty_cuts;

-- add claim, target and common core standards
ALTER TABLE item ADD COLUMN claim_code varchar(10);
ALTER TABLE item ADD COLUMN target_code varchar(10);
ALTER TABLE item ADD COLUMN common_core_standard_ids varchar(200);

update item i
   join claim c on c.id = i.claim_id
  set i.claim_code = c.code;

update item i
   join target t on t.id = i.target_id
  set i.target_code = t.code;

-- random for now, just to fill in the data
update item i
  set i.common_core_standard_ids = (select natural_id from common_core_standard limit 1);

ALTER TABLE item MODIFY COLUMN claim_code varchar(10) NOT NULL;
ALTER TABLE item MODIFY COLUMN target_code varchar(10) NOT NULL;
