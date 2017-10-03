/*
Initial data load for  SBAC RDW Olap Migrate 1.0.0
*/

USE ${schemaName};

INSERT INTO migrate_status (id, name) VALUES
  (-20, 'FAILED'),
  (-10, 'ABANDONED'),
  (10, 'STARTED'),
  (20, 'COMPLETED');
