# SELECT max(id) FROM import; -- 9969190
#
#
# SELECT
#   g.name        AS GroupName,
#   sc.natural_id AS SchoolIdentifier,
#   g.school_year AS SchoolYear,
#   'All'         AS Subject,
#   s.ssid        AS StudentIdentifier,
#   NULL          AS UserName
# FROM student_group g
#   JOIN school sc ON sc.id = g.school_id
#   JOIN student_group_membership sgm ON g.id = sgm.student_group_id
#   JOIN student s ON s.id = sgm.student_id;
#
# select count(*) from student; -- 222,308
#
# select count(*) from exam -- 9,969,186

GRANT LOAD FROM S3 ON *.* TO sbac;
# need to capture what Mark has done to grant the access

DROP TABLE IF EXISTS student_group_load;
CREATE TABLE IF NOT EXISTS student_group_load (
  id                BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  batch_id          BIGINT       NOT NULL,
  name              VARCHAR(255) NOT NULL,
  group_id          INT,
  school_natural_id VARCHAR(40)  NOT NULL,
  school_id         INT,
  school_year       SMALLINT     NOT NULL,
  subject_code      VARCHAR(10),
  subject_id        TINYINT,
  student_ssid      VARCHAR(65),
  student_id        BIGINT,
  group_user_login  VARCHAR(255),
  creator           VARCHAR(250),
  import_id         BIGINT
);

DROP TABLE IF EXISTS batch_group_load;
CREATE TABLE IF NOT EXISTS batch_group_load (
  id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  STATUS  TINYINT                                   NOT NULL,
  created TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  updated TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL
);

# TODO: this table is my temporary way of tracking the execution time of each step
DROP TABLE IF EXISTS batch_group_load_progress;
CREATE TABLE IF NOT EXISTS batch_group_load_progress (
  batch_id BIGINT,
  created  TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
  message  VARCHAR(256)
);

INSERT INTO batch_group_load (id, STATUS) VALUE (22, 0);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'start');

LOAD DATA FROM S3 's3-us-west-2://rdw-dev-archive/student_groups_new_student.csv'
INTO TABLE student_group_load
FIELDS TERMINATED BY ',' IGNORE 1 LINES
( NAME, school_natural_id, school_year, subject_code, student_ssid, group_user_login)
SET batch_id = 22,
creator = 'test';

INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'load csv');

# TODO: this is how it is done locally
# LOAD DATA INFILE '/Users/allagorina/development/patch/student_groups.csv'
# INTO TABLE student_group_load
# FIELDS TERMINATED BY ',' IGNORE 1 LINES
# (NAME, @school_id, school_year, @subject_code, student_ssid, group_user_login)
# SET
#   batch_id = 22,
#   creator  = 'test';


# validate the batch step
# 1. update school ids and subject_id. Combining two updates into one improves the performance
UPDATE student_group_load sgl
  JOIN school s ON sgl.school_natural_id = s.natural_id
  LEFT JOIN subject sub ON sub.code = sgl.subject_code
SET school_id = s.id,
  subject_id  = CASE WHEN sub.code IS NULL
    THEN -1
                ELSE sub.id END
WHERE batch_id = 22;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'update school and subject');

# TODO: validate user access here

# validate schools
SELECT 1
FROM student_group_load
WHERE school_id IS NULL AND batch_id = 22
LIMIT 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'validate school');

# validate subjects
SELECT 1
FROM student_group_load
WHERE subject_id IS NULL AND batch_id = 22
LIMIT 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'validate subject');

# validate that there is only one subject for a group name, school and year
# compare two counts below
SELECT count(*)
FROM (
       SELECT DISTINCT
         school_id,
         school_year,
         name,
         subject_id
       FROM student_group_load sgl
       WHERE batch_id = 22) AS count;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'count DISTINCT with subject');

SELECT count(*)
FROM (
       SELECT DISTINCT
         school_id,
         school_year,
         name
       FROM student_group_load sgl
       WHERE batch_id = 22) AS count;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'count DISTINCT');

# Considerations:
# - migrate will be suspended if we have import ids in state 0 for a long time
# - groups depend on the student, so it is safer to have student import id lower than the group import id
# - for the benefit of the migrate process, one import id should not be assigned to too many records ('too many' is larger than a school size)
# - while moving from the load to warehouse, we can do up to 1 mill in one transaction: # http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.BestPractices.html - 1 million  (

#TODO: test the size

# Because of the above, break the import into steps: first import students, then import groups

# First I was creating as many import ids as there are unique schools in the batch.
# For the case when there are not too many new students, I ended up with too many unused import ids
# Because of this, here I am trying to determine all schools that have any students that need to be changed
# TODO: review this
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT
    status,
    content,
    contentType,
    digest,
    batch
  FROM
    (
      SELECT DISTINCT
        0                     AS status,
        5                     AS content,
        'group batch student' AS contentType,
        school_id             AS digest,
        22                    AS batch
      FROM student_group_load sgl
        LEFT JOIN student s ON sgl.student_ssid = s.ssid
      WHERE s.id IS NULL AND sgl.batch_id = 22
      UNION
      SELECT DISTINCT
        0                     AS status,
        5                     AS content,
        'group batch student' AS contentType,
        school_id             AS digest,
        22                    AS batch
      FROM student_group_load sgl
        JOIN student s ON sgl.student_ssid = s.ssid
      WHERE s.deleted = 1 AND sgl.batch_id = 22
    ) AS student_import_ids;

# distribute import ids among the batch - one id per school, AND only for the schools that have ids
# TODO: discuss this
UPDATE student_group_load sgl
  JOIN (SELECT
          id,
          cast(digest AS UNSIGNED) AS school_id
        FROM import
        WHERE batch = '22' and status = 0) i  -- TODO: is this unique enough?
    ON i.school_id = sgl.school_id
SET sgl.import_id = i.id
WHERE batch_id = 22 AND student_ssid IS NOT NULL;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'updated import id, one per school');

##### TODO: transaction begin
# first insert anything with missing ssid
INSERT INTO student (ssid, import_id, update_import_id, gender_id) -- TODO: remove gender once a bug is fixed
  SELECT
    DISTINCT
    student_ssid,
    sgl.import_id,
    sgl.import_id,
    1
  FROM student_group_load sgl
    LEFT JOIN student s ON sgl.student_ssid = s.ssid
  WHERE s.id IS NULL AND sgl.batch_id = 22;
##### TODO: transaction end
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'insert new students into warehouse');

##### TODO: transaction begin
# now handle the deleted ones by resetting the delete flag
UPDATE student s
  JOIN (SELECT DISTINCT
          student_ssid,
          import_id,
          batch_id
        FROM student_group_load) sgl ON sgl.student_ssid = s.ssid
SET
  s.deleted          = 0,
  s.update_import_id = sgl.import_id
WHERE s.deleted = 1 AND sgl.batch_id = 22;
##### TODO: transaction end
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'updated deleted students in warehouse');

# trigger students migrate
UPDATE import
SET status = 1 -- or -1 if anything above failed
WHERE status = 0 AND
      id IN (SELECT distinct import_id
             FROM student_group_load
             WHERE student_ssid IS NOT NULL AND batch_id = 22);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'update import id to migrate students');

-- ----

# update student_id before we start group processing
UPDATE student_group_load sgl
  JOIN student s ON sgl.student_ssid = s.ssid
SET student_id = s.id
WHERE batch_id = 22;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'update student id in the load table');

# update existing group ids
UPDATE student_group_load sgl
  JOIN student_group sg ON sgl.name = sg.name and sg.school_id = sgl.school_id and sg.school_year = sgl.school_year
SET group_id = sg.id
WHERE batch_id = 22;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'update group id in the load table');

# import the groups


# TODO: we want to only migrate groups that have changed
# that means we want to update the import id only on those groups, hence we need to determine the delta
# the same group could have multiple changes
# multiple groups within a school could have a change
# we want one import id shared among all groups and all changes within a school?

# How to find how many import ids we need and assign them to the groups within schools
# this returns all school ids that have any groups changes
SELECT
  sgl.school_id
FROM student_group_load sgl
WHERE sgl.group_id IS NULL

UNION ALL

# school with added membership
SELECT
  sgl.school_id
FROM student_group_load sgl
  LEFT JOIN student_group_membership sgm ON (sgm.student_group_id = sgl.group_id AND sgm.student_id = sgl.student_id)
WHERE sgm.student_group_id IS NULL

UNION ALL

# school with the removed membership
# -TODO: this takes forever. seems like removing the inner query helps, do it java? - hash to compare!??
SELECT
  sg.school_id as id
FROM student_group_load sgl
  RIGHT JOIN student_group_membership sgm ON (sgm.student_group_id = sgl.group_id AND sgm.student_id = sgl.student_id)
  JOIN student_group sg on sg.id = sgm.student_group_id
WHERE sgl.group_id IS NULL and
      sgm.student_group_id in (select group_id from student_group_load where batch_id = 11)

UNION ALL

# school with added users
SELECT
  sgl.school_id
FROM student_group_load sgl
  LEFT JOIN user_student_group sgm ON (sgm.student_group_id = sgl.group_id AND sgm.user_login = sgl.group_user_login)
WHERE sgm.student_group_id IS NULL

UNION ALL

# school with the removed users
SELECT
  sgl.school_id
FROM user_student_group sgm
  LEFT JOIN student_group_load sgl ON (sgm.student_group_id = sgl.group_id AND sgm.user_login = sgl.group_user_login)
WHERE sgl.group_id IS NULL;


# generate a new set of import ids for the groups now
# TODO: this will create more imports ids than we potentially need. If there is no changes to the group, it will get an import id.
# Is it too bad?
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT
    status,
    content,
    contentType,
    digest,
    batch
  FROM
    (
      SELECT DISTINCT
        0             AS status,
        5             AS content,
        'group batch' AS contentType,
        school_id     AS digest,
        22            AS batch
      FROM student_group_load sgl
      WHERE sgl.batch_id = 22
    ) AS group_import_ids;

INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'generated import ids for te groups in the batch, one per school');

# TODO: do we need another column for the import_id for the groups? or is it okay to reuse?
UPDATE student_group_load sgl
  JOIN (SELECT
          id,
          cast(digest AS UNSIGNED) AS school_id
        FROM import
        WHERE batch = '22'and status = 0) i ON i.school_id = sgl.school_id
SET sgl.import_id = i.id
WHERE batch_id = 22 AND student_ssid IS NOT NULL;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'updated import id for groups, one per school');

# create new groups
##### TODO: transaction begin
INSERT INTO student_group (name, school_id, school_year, subject_id, creator, import_id, update_import_id)
  SELECT
    sgl.name,
    sgl.school_id,
    sgl.school_year,
    CASE WHEN sgl.subject_id = -1 then null
    ELSE sgl.subject_id END,
    sgl.creator,
    sgl.import_id,
    sgl.import_id
  FROM student_group_load sgl
  WHERE sgl.group_id IS NULL;

# TODO: we really do not update the groups this way, just the user access and membership. Is it right?
#  modify subject only

##### TODO: transaction end?

# update existing group ids - again
UPDATE student_group_load sgl
  JOIN student_group sg ON sgl.name = sg.name and sg.school_id = sgl.school_id and sg.school_year = sgl.school_year
SET group_id = sg.id
WHERE batch_id = 22 and group_id is null;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (22, 'update group id in the load table after creating new groups');

##### TODO: transaction begin
# TODO: add/delete student_group_membership

# TODO: add/delete user_student_group

# TODO: update student groups update_import_id with the import ids from the load table?

##### TODO: transaction end

#  TODO: add modifier and modified date to

#
# UPDATE import
# SET status = 1 -- or -1 ?
# WHERE id IN (..);
#
#
# DELETE FROM student_group_load
# WHERE batch_id = :batch_id
#
#
# TODO: abandoned/not finished loads - use created timestamp and delete based on that?
