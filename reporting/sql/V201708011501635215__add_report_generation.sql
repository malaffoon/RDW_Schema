-- Add a report_generation table to track user report requests

USE ${schemaName};

CREATE TABLE IF NOT EXISTS report_generation (
  id bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_login varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  job_execution_id bigint(20),
  status tinyint(4) NOT NULL,
  report_resource_uri varchar(255),
  label varchar(255) NOT NULL,
  report_request text NOT NULL,
  created TIMESTAMP(6) NOT NULL,
  KEY idx__report_generation__user_login_label (user_login, label),
  KEY idx__report_generation__created (created)
);