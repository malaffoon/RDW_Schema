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

# TODO: add creator too
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

DROP TABLE IF EXISTS student_group_load_import;
CREATE TABLE IF NOT EXISTS student_group_load_import (
  id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  batch_id  BIGINT       NOT NULL,
  school_id INT,
  import_id BIGINT,
  ref       VARCHAR(255) NOT NULL,
  ref_type  TINYINT, -- 1 = student , 2 = groups
  UNIQUE INDEX idx__student_group_load_import__batch_ref (batch_id, ref)
);

INSERT INTO batch_group_load (id, STATUS) VALUE (34, 0);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'start');

LOAD DATA FROM S3 's3-us-west-2://rdw-dev-archive/student_groups_sample.csv'
INTO TABLE student_group_load
FIELDS TERMINATED BY ',' IGNORE 1 LINES
( NAME, school_natural_id, school_year, subject_code, student_ssid, group_user_login)
SET batch_id = 34,
creator = 'test';

INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'load csv');

# TODO: this is how it is done locally
# LOAD DATA INFILE '/Users/allagorina/development/patch/student_groups.csv'
# INTO TABLE student_group_load
# FIELDS TERMINATED BY ',' IGNORE 1 LINES
# (NAME, @school_id, school_year, @subject_code, student_ssid, group_user_login)
# SET
#   batch_id = 34,
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
WHERE batch_id = 34;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update school and subject');

# TODO: validate user access here

# validate schools
SELECT 1
FROM student_group_load
WHERE school_id IS NULL AND batch_id = 34
LIMIT 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'validate school');

# validate subjects
SELECT 1
FROM student_group_load
WHERE subject_id IS NULL AND batch_id = 34
LIMIT 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'validate subject');

# replace empty with null
UPDATE student_group_load
SET group_user_login = NULL
WHERE group_user_login = '';
UPDATE student_group_load
SET student_ssid = NULL
WHERE student_ssid = '';

# TODO: validate groups size

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
       WHERE batch_id = 34) AS count;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'count DISTINCT with subject');

SELECT count(*)
FROM (
       SELECT DISTINCT
         school_id,
         school_year,
         name
       FROM student_group_load sgl
       WHERE batch_id = 34) AS count;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'count DISTINCT');

# update existing students
UPDATE student_group_load sgl
  JOIN student s ON sgl.student_ssid = s.ssid
SET student_id = s.id
WHERE batch_id = 34;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update student id in the load table, first time');

# update existing groups
UPDATE student_group_load sgl
  JOIN student_group sg ON sgl.name = sg.name
SET group_id = sg.id
WHERE batch_id = 34;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update student id in the load table, first time');

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
# TODO: review this, modify import to have batch_ref_id and ref_id fields

# cache a school that have students that need an import id. If the same student happens in two schools (for some reason) only one school will be selected
INSERT IGNORE INTO student_group_load_import (batch_id, school_id, ref, ref_type)
#   new students
  SELECT
    batch_id,
    school_id,
    student_ssid,
    1
  FROM student_group_load sgl
  WHERE sgl.student_id IS NULL AND sgl.student_ssid IS NOT NULL AND sgl.batch_id = 34
  UNION ALL
  #     deleted students that are in the groups
  SELECT
    batch_id,
    school_id,
    student_ssid,
    1
  FROM student_group_load sgl
    JOIN student s ON sgl.student_ssid = s.ssid
  WHERE s.deleted = 1 AND sgl.student_ssid IS NOT NULL AND sgl.batch_id = 34;

INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'load student_group_load_import with ids for students');

# create one import id per each cached schools
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT DISTINCT
    -- we want one school for all students, hence the distinct
    0                     AS status,
    5                     AS content,
    'group batch student' AS contentType,
    school_id             AS digest,
    34                    AS batch
  FROM student_group_load_import sgl
  WHERE batch_id = 34 AND ref_type = 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'create import ids for students');

# assign import ids to all records that have school
UPDATE student_group_load_import sgl
  JOIN (SELECT
          id,
          cast(digest AS UNSIGNED) AS school_id
        FROM import
        WHERE batch = '34' AND status = 0) AS si
    ON si.school_id = sgl.school_id
SET sgl.import_id = si.id;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update student_group_load_import with import ids for students');

# distribute import ids among the batch - one id per school, AND only for the records that will be imported
UPDATE student_group_load sgl
  JOIN student_group_load_import i
    ON i.school_id = sgl.school_id
SET sgl.import_id = i.import_id
WHERE sgl.batch_id = 34 AND student_id IS NULL;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'updated student_group_load import id, one per school');

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
  WHERE s.id IS NULL AND sgl.student_ssid IS NOT NULL AND sgl.import_id IS NOT NULL AND sgl.batch_id = 34; -- todo: is there a better way ?
##### TODO: transaction end
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'insert new students into warehouse');

##### TODO: transaction begin
# now handle the deleted ones by resetting the delete flag
UPDATE student s
  JOIN student_group_load sgl ON sgl.student_id = s.id
SET
  s.deleted          = 0,
  s.update_import_id = sgl.import_id
WHERE s.deleted = 1 AND sgl.student_ssid IS NOT NULL AND sgl.import_id IS NOT NULL AND sgl.batch_id = 34;
##### TODO: transaction end
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'updated deleted students in warehouse');

# trigger students migrate
UPDATE import i
  JOIN student_group_load_import sgli ON sgli.import_id = i.id
SET i.status = 1 -- or -1 if anything above failed
WHERE i.status = 0 AND sgli.batch_id = 34 AND sgli.ref_type = 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update import id to migrate students');

# update student_id before we start group processing
UPDATE student_group_load sgl
  JOIN student s ON sgl.student_ssid = s.ssid
SET sgl.student_id = s.id
WHERE batch_id = 34 AND student_id IS NULL;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update student id in the load table');

# import the groups

# We want to only migrate groups that have changed
# that means we want to update the import id only on those groups, hence we need to determine the delta
# the same group could have multiple changes
# multiple groups within a school could have a change
# we want one import id shared among all groups and all changes within a school?

# How to find how many import ids we need and assign them to the groups within schools
# this returns all school ids that have any groups changes
INSERT IGNORE INTO student_group_load_import (batch_id, school_id, ref, ref_type)
  SELECT
    sgl.batch_id,
    sgl.school_id,
    sgl.name,
    2
  FROM student_group_load sgl
  WHERE sgl.group_id IS NULL

  UNION ALL

  # school with changed membership
  SELECT
    batch_id,
    school_id,
    name,
    2
  FROM (
         SELECT
           batch_id,
           school_id,
           group_id,
           name,
           GROUP_CONCAT(student_id ORDER BY student_id SEPARATOR ',') AS students
         FROM student_group_load
         WHERE student_id IS NOT NULL AND batch_id = 34
         GROUP BY group_id) AS loading
    LEFT JOIN
    (
      SELECT
        student_group_id,
        GROUP_CONCAT(student_id ORDER BY student_id SEPARATOR ',') AS students
      FROM student_group_membership
      GROUP BY student_group_id
    ) AS existing
      ON existing.student_group_id = loading.group_id
  WHERE existing.students <> loading.students

  UNION ALL

  # school with changed users
  SELECT
    batch_id,
    school_id,
    name,
    2
  FROM (
         SELECT
           batch_id,
           school_id,
           group_id,
           name,
           GROUP_CONCAT(group_user_login ORDER BY group_user_login SEPARATOR ',') AS users
         FROM student_group_load
         WHERE group_user_login IS NOT NULL AND batch_id = 34
         GROUP BY group_id) AS loading
    LEFT JOIN
    (
      SELECT
        student_group_id,
        GROUP_CONCAT(user_login ORDER BY user_login SEPARATOR ',') AS users
      FROM user_student_group
      GROUP BY student_group_id
    ) AS existing
      ON existing.student_group_id = loading.group_id
  WHERE existing.users <> loading.users;

INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'generated cached import ids for the groups in the batch, one per school');

-- TODO: tested up to here

# generate a new set of import ids for the groups now
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT DISTINCT
    0             AS status,
    5             AS content,
    'group batch' AS contentType,
    school_id     AS digest,
    34            AS batch
  FROM student_group_load_import sgl
  WHERE batch_id = 34 AND ref_type = 2;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'generated import ids for the groups in the batch, one per school');

# TODO: consider a different import id for the group or a ref_id
UPDATE student_group_load sgl
  JOIN student_group_load_import i ON sgl.school_id = i.school_id
SET sgl.import_id = i.import_id
WHERE batch_id = 34 AND student_ssid IS NOT NULL AND i.ref_type = 2;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'updated import id for groups, one per school');

# create new groups
##### TODO: transaction begin
INSERT IGNORE INTO student_group (name, school_id, school_year, subject_id, creator, import_id, update_import_id)
  SELECT
    sgl.name,
    sgl.school_id,
    sgl.school_year,
    CASE WHEN sgl.subject_id = -1
      THEN NULL
    ELSE sgl.subject_id END,
    sgl.creator,
    sgl.import_id,
    sgl.import_id
  FROM student_group_load sgl
  WHERE sgl.group_id IS NULL;

UPDATE student_group sg
  JOIN student_group_load sgl ON sgl.group_id = sg.id
SET sg.subject_id = CASE WHEN sgl.subject_id = -1
  THEN NULL
                    ELSE sgl.subject_id END
WHERE sgl.batch_id = 34;
-- TODO: check that import ids do not conflict here
##### TODO: transaction end?
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'moved groups over');

# update existing group ids - again
UPDATE student_group_load sgl
  JOIN student_group sg ON sgl.name = sg.name AND sg.school_id = sgl.school_id AND sg.school_year = sgl.school_year
SET group_id = sg.id
WHERE batch_id = 34 AND group_id IS NULL;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update group id in the load table after creating new groups');

##### TODO: transaction begin
# add/delete user_student_group

INSERT IGNORE INTO user_student_group (student_group_id, user_login)
  SELECT
    susg.group_id,
    susg.group_user_login
  FROM student_group_load susg
    LEFT JOIN user_student_group rusg ON (rusg.student_group_id = susg.group_id AND rusg.user_login = susg.group_user_login)
  WHERE rusg.user_login IS NULL
        AND susg.batch_id = 34
        AND group_user_login IS NOT NULL;


DELETE rsug FROM user_student_group rsug
  JOIN student_group_load ssg ON ssg.group_id = rsug.student_group_id
WHERE
  ssg.batch_id = 34
  AND
  NOT EXISTS(
      SELECT 1
      FROM student_group_load susg
      WHERE
        susg.group_id = rsug.student_group_id
        AND susg.group_user_login = rsug.user_login
  );

# add/delete student_group_membership

INSERT IGNORE INTO student_group_membership (student_group_id, student_id)
  SELECT
    susg.group_id,
    susg.student_id
  FROM student_group_load susg
    LEFT JOIN student_group_membership rusg ON (rusg.student_group_id = susg.group_id AND rusg.student_id = susg.student_id)
  WHERE rusg.student_id IS NULL
        AND susg.batch_id = 34
        AND susg.student_id IS NOT NULL;

DELETE rsug
FROM
  student_group_membership rsug
  JOIN student_group_load ssg ON ssg.group_id = rsug.student_group_id
WHERE
  ssg.batch_id = 34
  AND
  NOT EXISTS(
      SELECT 1
      FROM student_group_load susg
      WHERE
        susg.group_id = rsug.student_group_id
        AND susg.student_id = rsug.student_id
  );
# TODO: update student groups update_import_id with the import ids

update student_group sg
  JOIN student_group_load sgl on sgl.group_id = sg.id
SET update_import_id = sgl.import_id
where sgl.import_id is not null and sgl.batch_id = 34;
##### TODO: transaction end

# trigger students migrate
UPDATE import i
  JOIN student_group_load_import sgli ON sgli.import_id = i.id
SET i.status = 1 -- or -1 if anything above failed
WHERE i.status = 0 AND sgli.batch_id = 34 AND sgli.ref_type = 2;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update import id to migrate students');


#  TODO: add modifier and modified date to student group table


# clean up
#  TODO: DELETE FROM student_group_load WHERE batch_id = 34;



#
# TODO: abandoned/not finished loads - use created timestamp and delete based on that?


# SHOW VARIABLES group_concat_max_len;

# SET [GLOBAL | SESSION] group_concat_max_len = val; 1024
# max_allowed_packet	4194304

