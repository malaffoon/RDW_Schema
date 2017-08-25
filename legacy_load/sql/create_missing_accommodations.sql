-- create missing legacy accommodations

use warehouse;

INSERT INTO warehouse.import (status, content, contentType, digest) VALUES (0, 3, 'missing legacy accommodations', 'missing legacy accommodations');
SELECT LAST_INSERT_ID() INTO @importid;

INSERT INTO accommodation (code) VALUES
 ('ENU-Braille'),
 ('NEDS_NoiseBuf');

 INSERT INTO accommodation_translation (accommodation_id, language_id, label) VALUES
  ((SELECT id from accommodation WHERE code = 'ENU-Braille') , 1, 'Braille'),
  ((SELECT id from accommodation WHERE code = 'NEDS_NoiseBuf'), 1, 'Noise Buffers');

UPDATE import
 SET status = 1
WHERE id = @importid;