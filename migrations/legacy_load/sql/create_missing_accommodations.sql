-- create missing legacy accommodations

use warehouse;

INSERT INTO import (status, content, contentType, digest) VALUES (0, 3, 'missing legacy accommodations', 'missing legacy accommodations');
SELECT LAST_INSERT_ID() INTO @importid;

INSERT INTO accommodation (code) VALUES
 ('ENU-Braille');

 INSERT INTO accommodation_translation (accommodation_id, language_id, label) VALUES
  ((SELECT id from accommodation WHERE code = 'ENU-Braille') , 1, 'Braille');

UPDATE import
 SET status = 1
WHERE id = @importid;