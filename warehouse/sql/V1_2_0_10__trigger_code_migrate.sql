USE ${schemaName};

--TODO: NOTE this for production release unless configurable subject change this somehow
-- Trigger migration of all the codes; the goal is to populate target/natural_id column
INSERT INTO import(status, content, contentType, digest)
  SELECT 1, ic.id, 'reload codes', left(uuid(), 8) from import_content ic where name = 'CODES';