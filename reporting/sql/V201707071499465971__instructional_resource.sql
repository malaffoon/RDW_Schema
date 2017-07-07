# add instructional_resource

USE ${schemaName};

/**  Instructional resources to store mapping from assessment id to an external resource URL. **/
/**  This table will be loaded/updated manually. **/

CREATE TABLE IF NOT EXISTS instructional_resource (
  id int NOT NULL PRIMARY KEY,
  resource text NOT NULL
 );
