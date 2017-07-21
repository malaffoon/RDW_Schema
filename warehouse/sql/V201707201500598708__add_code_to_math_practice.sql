# add code to math_practice

USE ${schemaName};

ALTER TABLE math_practice ADD COLUMN code VARCHAR(4);
UPDATE math_practice SET code = practice;
ALTER TABLE math_practice MODIFY code VARCHAR(4) NOT NULL;
ALTER TABLE math_practice ADD UNIQUE INDEX idx__math_practice_code (code);
