/**
** add claim 1-4 codes from the exam table to the asmt
** for IAB they will always be null, for other exams it depends on the the number of claims per subject
**/

USE ${schemaName};

alter TABLE asmt add COLUMN claim_1_score_code varchar(10);
alter TABLE asmt add COLUMN claim_2_score_code varchar(10);
alter TABLE asmt add COLUMN claim_3_score_code varchar(10);
alter TABLE asmt add COLUMN claim_4_score_code varchar(10);

UPDATE asmt a
  JOIN (SELECT code as claim1, s.subject_id, s.asmt_type_id FROM subject_claim_score s
          JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.id AND m.num = 1)
    AS s1 ON a.subject_id = s1.subject_id AND a.type_id = s1.asmt_type_id

  JOIN (SELECT code as claim2, s.subject_id, s.asmt_type_id FROM subject_claim_score s
          JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.id AND m.num = 2)
    AS s2 ON a.subject_id = s2.subject_id AND a.type_id = s2.asmt_type_id

  JOIN (SELECT code as claim3, s.subject_id, s.asmt_type_id FROM subject_claim_score s
          JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.id AND m.num = 3)
    AS s3 ON a.subject_id = s3.subject_id AND a.type_id = s3.asmt_type_id

  LEFT JOIN (SELECT code as claim4, s.subject_id, s.asmt_type_id FROM subject_claim_score s
               JOIN exam_claim_score_mapping m ON m.subject_claim_score_id = s.id AND m.num = 4)
    AS s4 ON a.subject_id = s4.subject_id AND a.type_id = s4.asmt_type_id
SET
  a.claim_1_score_code = claim1,
  a.claim_2_score_code = claim2,
  a.claim_3_score_code = claim3,
  a.claim_4_score_code = claim4;