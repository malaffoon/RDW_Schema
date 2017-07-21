# misc denormalization

USE ${schemaName};

# denormalize exam available accommodation codes
ALTER TABLE exam ADD COLUMN available_accommodation_codes VARCHAR(500);
UPDATE exam e
    LEFT JOIN
      (SELECT
         eaa.exam_id as exam_id,
         GROUP_CONCAT(a.code ORDER BY a.id SEPARATOR '|') AS codes
       FROM exam_available_accommodation eaa
         JOIN accommodation a ON a.id = eaa.accommodation_id
       GROUP BY eaa.exam_id
      ) AS code ON code.exam_id = e.id
SET e.available_accommodation_codes = code.codes;

# denormalize dok as a combination of level and subject
ALTER TABLE item ADD COLUMN dok_level_subject_id VARCHAR(9);
UPDATE item i
    JOIN depth_of_knowledge dok ON dok.id = i.dok_id
SET i.dok_level_subject_id = concat(dok.level, '_', dok.subject_id);
ALTER TABLE item MODIFY dok_level_subject_id VARCHAR(9) NOT NULL;

# add code to math_practice
ALTER TABLE math_practice ADD COLUMN code VARCHAR(4);
UPDATE math_practice SET code = practice;
ALTER TABLE math_practice  MODIFY code VARCHAR(4) NOT NULL;
ALTER TABLE math_practice ADD UNIQUE INDEX idx__math_practice_code (code);

# denormalize math_practice in the item table
ALTER TABLE item ADD COLUMN math_practice_code VARCHAR(4);
UPDATE item i SET i.math_practice_code = i.math_practice;