USE ${schemaName};

--TODO: NOTE remove this file from the production release
-- trigger migration of summative assessments to load asmt_target table in reporting data-mart
 INSERT INTO import (status, content, contentType, digest)
    SELECT 0, ic.id, 'force summative asmt migrate', left(uuid(), 8) from import_content ic where name = 'PACKAGE';

 SELECT max(id) INTO @import_id
    FROM IMPORT WHERE contentType = 'force summative asmt migrate';

 UPDATE asmt
    SET update_import_id = @import_id
    WHERE type_id = 3;

 UPDATE import
    SET status = 1
    WHERE id = @import_id;
