/**
** 	Add tables for persisting import resources
**/

USE warehouse;

CREATE TABLE IF NOT EXISTS import_content (
  id tinyint NOT NULL PRIMARY KEY,
  name varchar(20) NOT NULL UNIQUE
);

INSERT INTO import_content (id, name) VALUES
  (1, 'EXAM');

CREATE TABLE IF NOT EXISTS import_status (
  id tinyint NOT NULL PRIMARY KEY,
  name varchar(20) NOT NULL UNIQUE
);

INSERT INTO import_status (id, name) VALUES
  (-5, 'UNKNOWN_ASMT'),
  (-4, 'UNAUTHORIZED'),
  (-3, 'BAD_DATA'),
  (-2, 'BAD_FORMAT'),
  (-1, 'INVALID'),
  (0, 'ACCEPTED'),
  (1, 'PROCESSED'),
  (2, 'PUBLISHED');

CREATE TABLE IF NOT EXISTS import (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  status tinyint NOT NULL,
  content tinyint NOT NULL,
  contentType varchar(250) NOT NULL,
  digest varchar(32) NOT NULL,
  batch varchar(250),
  creator varchar(250),
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  message varchar(500)
);