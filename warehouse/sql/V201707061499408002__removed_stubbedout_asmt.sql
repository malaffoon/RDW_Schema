# removed asmt_safe_create and added new import status

USE ${schemaName};

DROP PROCEDURE IF EXISTS asmt_safe_create;

INSERT INTO import_status (id, name) VALUES
  (-6, 'UNKNOWN_SCHOOL');
