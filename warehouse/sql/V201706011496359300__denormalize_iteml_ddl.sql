/**
* DWR-397 Denormalize/calculate item data during asmt package loading
**/

USE ${schemaName};

CREATE INDEX idx__asmt_type_subject_grade ON asmt (type_id, subject_id, grade_id);


--  it is nullable here because we want to insert all the records without it and then update beased on the difficulty
--  supported values are E, M, D
ALTER TABLE item ADD COLUMN difficulty_code varchar(1);

update item i
  join asmt a on i.asmt_id = a.id
  join item_difficulty_cuts c on c.asmt_type_id = a.type_id and a.subject_id = c.subject_id and a.grade_id = c.grade_id
set
  i.difficulty_code = if(i.difficulty < c.moderate_low_end, 'L', if(i.difficulty < c.difficult_low_end, 'M', 'D' ));
