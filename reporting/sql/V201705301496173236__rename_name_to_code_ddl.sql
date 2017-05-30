/**
** Rename name to code
**/

USE ${schemaName};

-- NOTE that the UNIQUE is not needed since mySQL will use the existing index
ALTER TABLE subject CHANGE name code varchar(10) NOT NULL;
ALTER TABLE completeness CHANGE name code varchar(10) NOT NULL;
ALTER TABLE administration_condition CHANGE name code varchar(20) NOT NULL;
ALTER TABLE ethnicity CHANGE name code varchar(255) NOT NULL;
ALTER TABLE gender CHANGE name code varchar(255) NOT NULL;

