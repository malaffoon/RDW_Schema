USE ${schemaName};

CREATE TABLE IF NOT EXISTS user_query (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_login varchar(255) NOT NULL,
  label varchar(255) NOT NULL,
  query text NOT NULL,
  created timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx__user_query__user_login (user_login)
);
