# add instructional_resource

USE ${schemaName};

/**  Instructional resources to store mapping from assessment id to an external resource URL. **/
/**  This table will be loaded/update manually. **/

CREATE TABLE IF NOT EXISTS instructional_resource (
  id int NOT NULL PRIMARY KEY,
  resource varchar(1000) NOT NULL
 );
