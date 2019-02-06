-- Hand-crafted SQL to delete a subject from QA and dev environments.
-- Which, of course, means deleting that subject's assessments.
-- Which, of course, means deleting those assessments' exams.
-- Which can allow us to delete students who no longer have exams.
--
-- This assumes that the reporting databases will be wiped and remigrated.
-- It does hard-deletes without import/migrate. It ignores audit tables.

USE warehouse;

SET @delete_subject_id = 5;

-- Delete exams for the assessments of the subject
DELETE ei FROM exam_item ei
  JOIN exam e ON ei.exam_id = e.id
  JOIN asmt a ON e.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE eaa FROM exam_available_accommodation eaa
  JOIN exam e ON eaa.exam_id = e.id
  JOIN asmt a ON e.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE ets FROM exam_target_score ets
  JOIN exam e ON ets.exam_id = e.id
  JOIN asmt a ON e.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE ecs FROM exam_claim_score ecs
  JOIN exam e ON ecs.exam_id = e.id
  JOIN asmt a ON e.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE exam FROM exam
  JOIN asmt a ON exam.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

-- Delete assessments of the subject
DELETE iot FROM item_other_target iot
  JOIN item i ON iot.item_id = i.id
  JOIN asmt a ON i.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE iccs FROM item_common_core_standard iccs
  JOIN item i ON iccs.item_id = i.id
  JOIN asmt a ON i.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE item FROM item
  JOIN asmt a ON item.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE assc FROM asmt_score assc
  JOIN asmt a ON assc.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE ate FROM asmt_target_exclusion ate
  JOIN asmt a ON ate.asmt_id = a.id
WHERE a.subject_id = @delete_subject_id;

DELETE asmt FROM asmt
WHERE subject_id = @delete_subject_id;

-- Delete the subject
DELETE st FROM subject_translation st
  JOIN subject s ON st.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE scs FROM subject_claim_score scs
  JOIN subject s ON scs.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE sat FROM subject_asmt_type sat
  JOIN subject s ON sat.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE t FROM target t
  JOIN claim c on t.claim_id = c.id
  JOIN subject s on c.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE c FROM claim c
  JOIN subject s on c.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE ccs FROM common_core_standard ccs
  JOIN subject s on ccs.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE idc FROM item_difficulty_cuts idc
  JOIN subject s on idc.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE dok FROM depth_of_knowledge dok
  JOIN subject s on dok.subject_id = s.id
WHERE s.id = @delete_subject_id;

DELETE subject FROM subject
WHERE id = @delete_subject_id;


-- Delete students who now have no exams
DELETE se FROM student_ethnicity se
  JOIN student s on se.student_id = s.id
  LEFT JOIN exam e on s.id = e.student_id
WHERE e.id IS NULL;

DELETE sgm FROM student_group_membership sgm
  JOIN student s ON sgm.student_id = s.id
  LEFT JOIN exam e on s.id = e.student_id
WHERE e.id IS NULL;

DELETE student FROM student
  LEFT JOIN exam e on student.id = e.student_id
WHERE e.id IS NULL;
