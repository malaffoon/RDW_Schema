-- Add exam target scores
USE ${schemaName};

--TODO: change it to NOT NULL after configurable subject migrate is done?
ALTER TABLE target ADD natural_id varchar(20);

CREATE TABLE asmt_target (
  asmt_id int NOT NULL,
  target_id smallint NOT NULL,
  include_in_report tinyint NOT NULL,
  PRIMARY KEY(asmt_id, target_id),
  INDEX idx__asmt_target__target (target_id),
  CONSTRAINT fk__asmt_target__asmt FOREIGN KEY(asmt_id) REFERENCES asmt(id),
  CONSTRAINT fk__asmt_target__target FOREIGN KEY(target_id) REFERENCES target(id)
);

CREATE TABLE exam_target_score (
  id bigint NOT NULL PRIMARY KEY,
  exam_id bigint NOT NULL,
  target_id smallint NOT NULL,
  student_relative_residual_score float,
  standard_met_relative_residual_score float,
  INDEX idx__exam_target_score__targer (target_id),
  UNIQUE INDEX idx__exam_target_score__exam_target (exam_id, target_id),
  CONSTRAINT fk__exam_target_score__exam FOREIGN KEY (exam_id) REFERENCES exam(id),
  CONSTRAINT fk__exam_target_score__target FOREIGN KEY (target_id) REFERENCES target(id)
);