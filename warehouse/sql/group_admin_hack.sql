USE warehouse;

########################################### schema changes ###########################################

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

# TODO: add creator
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
  ref       VARCHAR(255) NOT NULL, -- either a student ssid or group name, use this along with the unique index below to de-dupe
  ref_type  TINYINT, -- 1 = new student, 0 = restore deleted student, 2 = new groups, 3 = modified groups membership, 4 = modified user, 5 = modified group
  UNIQUE INDEX idx__student_group_load_import__batch_ref (batch_id, ref)
);

########################################### start batch processing ###########################################
INSERT INTO batch_group_load (id, STATUS) VALUE (34, 0);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'start');

# LOAD DATA FROM S3 's3-us-west-2://rdw-dev-archive/student_groups_sample.csv'
# INTO TABLE student_group_load
# FIELDS TERMINATED BY ',' IGNORE 1 LINES
# ( NAME, school_natural_id, school_year, subject_code, student_ssid, group_user_login)
# SET batch_id = 34,
# creator = 'test';

# TODO: research loading empty vs null and the end of line chars. Have some issues with the large file in this regards
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'load csv');

LOAD DATA INFILE '/Users/allagorina/development/patch/student_groups_sample.csv'
INTO TABLE student_group_load
FIELDS TERMINATED BY ',' IGNORE 1 LINES
(NAME, school_natural_id, school_year, subject_code, student_ssid, group_user_login)
SET batch_id = 34,
  creator    = 'test';

########################################### validation ###########################################

# update school ids and subject_id (combining two updates into one improves the performance)
UPDATE student_group_load sgl
  JOIN school s ON sgl.school_natural_id = s.natural_id
  LEFT JOIN subject sub ON sub.code = sgl.subject_code
SET school_id = s.id,
  subject_id  = CASE WHEN sub.code IS NULL
    THEN -1 ELSE sub.id END
WHERE batch_id = 34;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update school and subject');

# TODO: validate user access here

# check if there is at least on null school id, if yes - we have unknown schools
SELECT 1
FROM student_group_load
WHERE school_id IS NULL AND batch_id = 34
LIMIT 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'validate school');

# check if there is at least one null subject, if yes - we have unknown subjects
SELECT 1
FROM student_group_load
WHERE subject_id IS NULL AND batch_id = 34
LIMIT 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'validate subject');

# replace empty values with null
UPDATE student_group_load
SET group_user_login = NULL
WHERE group_user_login = '' AND batch_id = 34;

UPDATE student_group_load
SET student_ssid = NULL
WHERE student_ssid = '' AND batch_id = 34;

# validate groups size, must be less than 200
SELECT
  count(*),
  name
FROM student_group_load
WHERE batch_id = 34
GROUP BY name;

# validate that groups have either users or students -optional
SELECT *
FROM student_group_load
WHERE batch_id = 34 AND student_ssid IS NULL AND group_user_login IS NULL
LIMIT 1;

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

# TODO: consider validating the size of the file and rejecting if larger than 1 mil?


########################################### post-validation ###########################################

# update existing students
UPDATE student_group_load sgl
  JOIN student s ON sgl.student_ssid = s.ssid
SET student_id = s.id
WHERE batch_id = 34 and s.deleted = 0;
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
# Because of the above, break the import into steps: first import students, then import groups

#TODO: test the whole process with the large batch file - 1 mil records?

########################################### import students ###########################################

# First I was creating as many import ids as there are unique schools in the batch.
# For the case when there are not too many new students, I ended up with too many unused import ids
# Because of this, here I am trying to determine all schools that have any students that need to be changed

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
    0
  FROM student_group_load sgl
    JOIN student s ON sgl.student_ssid = s.ssid
  WHERE s.deleted = 1 AND sgl.student_ssid IS NOT NULL AND sgl.batch_id = 34;

INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'load student_group_load_import with ids for students');

# create one import id per each cached schools
# TODO: review this, modify import table to have batch_ref_id and ref_id fields
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT DISTINCT
    -- we want one school for all students, hence the distinct
    0                     AS status,
    5                     AS content,
    'group batch student' AS contentType,
    school_id             AS digest, -- this will be ref_id instead of digest ?
    34                    AS batch -- this will be batch_ref_id ?
  FROM student_group_load_import sgl
  WHERE batch_id = 34 AND ref_type IN (0, 1);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'create import ids for students');

# assign import ids to all records that have school
UPDATE student_group_load_import sgl
  JOIN (SELECT
          id,
          cast(digest AS UNSIGNED) AS school_id
        FROM import
        WHERE batch = '34' AND status = 0 AND contentType = 'group batch student') AS si
    ON si.school_id = sgl.school_id
SET sgl.import_id = si.id
WHERE sgl.batch_id = 34 AND i.ref_type IN (0, 1);
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
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'insert new students into warehouse');
##### TODO: transaction end

##### TODO: transaction begin
# now handle the deleted ones by resetting the delete flag
UPDATE student s
  JOIN student_group_load sgl ON sgl.student_id = s.id
SET
  s.deleted          = 0,
  s.update_import_id = sgl.import_id
WHERE s.deleted = 1 AND sgl.student_ssid IS NOT NULL AND sgl.import_id IS NOT NULL AND sgl.batch_id = 34;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'updated deleted students in warehouse');
##### TODO: transaction end

# trigger students migrate
UPDATE import i
  JOIN student_group_load_import sgli ON sgli.import_id = i.id
SET i.status = 1 -- or -1 if anything above failed
WHERE i.status = 0 AND sgli.batch_id = 34 AND sgli.ref_type = 1;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update import id to migrate students');

########################################### group processing ###########################################

# update student_id before we start group processing
UPDATE student_group_load sgl
  JOIN student s ON sgl.student_ssid = s.ssid
SET sgl.student_id = s.id
WHERE batch_id = 34 AND student_id IS NULL;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update student id in the load table');

# remove processed import ids
UPDATE student_group_load sgl
SET import_id = NULL
WHERE batch_id = 34;

# We want to only migrate groups that have changed
# that means we want to update the import id only on those groups, hence we need to determine the delta
# the same group could have multiple changes
# multiple groups within a school could have a change
# we want one import id shared among all groups and all changes within a school?

# this returns all school ids that have any groups changes
# TODO:  we will need to adjust group_concat_max_len to something larger than the default = 1024
#  SHOW VARIABLES group_concat_max_len;
# SET [GLOBAL | SESSION] group_concat_max_len = val; 1024
# max_allowed_packet	4194304 - this is the max limit
INSERT IGNORE INTO student_group_load_import (batch_id, school_id, ref, ref_type)
# school with new groups
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
    3
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
    4
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
  WHERE existing.users <> loading.users

  UNION ALL

  #schools with the existing groups that have changes     
  SELECT
    sgl.batch_id,
    sgl.school_id,
    sgl.name,
    5
  FROM student_group_load sgl
    JOIN student_group sg ON sg.id = sgl.group_id
  WHERE ifnull(sg.subject_id, -1) != sgl.subject_id;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'generated cached import ids for the groups in the batch, one per school');

# generate a new set of import ids for the groups 
INSERT INTO import (status, content, contentType, digest, batch)
  SELECT DISTINCT
    0             AS status,
    5             AS content,
    'group batch' AS contentType,
    school_id     AS digest,
    34            AS batch
  FROM student_group_load_import sgl
  WHERE batch_id = 34 AND ref_type IN (2, 3, 4, 5);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'generated import ids for the groups in the batch, one per school');

# assign import ids to all records that have school
UPDATE student_group_load_import sgl
  JOIN (SELECT
          id,
          cast(digest AS UNSIGNED) AS school_id
        FROM import
        WHERE batch = '34' AND status = 0 AND contentType = 'group batch') AS si
    ON si.school_id = sgl.school_id
SET sgl.import_id = si.id
WHERE sgl.batch_id = 34 AND i.ref_type IN (2, 3, 4, 5);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update student_group_load_import with import ids for students');

UPDATE student_group_load sgl
  JOIN student_group_load_import i ON sgl.school_id = i.school_id
SET sgl.import_id = i.import_id
WHERE sgl.batch_id = 34 AND i.ref_type IN (2, 3, 4, 5);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'updated import id for groups, one per school');

# create new groups
##### TODO: transaction begin
INSERT IGNORE INTO student_group (name, school_id, active, school_year, subject_id, creator, import_id, update_import_id)
  SELECT
    sgl.name,
    sgl.school_id,
    1,
    sgl.school_year,
    CASE WHEN sgl.subject_id = -1
      THEN NULL
    ELSE sgl.subject_id END,
    sgl.creator,
    sgl.import_id,
    sgl.import_id
  FROM student_group_load sgl
  WHERE sgl.group_id IS NULL;

# update existing groups
#  TODO: add modifier and modified date to student group table
UPDATE student_group sg
  JOIN student_group_load sgl ON sgl.group_id = sg.id
SET sg.subject_id = CASE WHEN sgl.subject_id = -1
  THEN NULL
                    ELSE sgl.subject_id END
WHERE sgl.batch_id = 34;
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'moved groups over');
##### TODO: transaction end? - not sure about the end here, maybe wrap it around all group changes?

# update existing group ids - again. At this point we must have all groups with ids
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

# update student groups update_import_id
UPDATE student_group sg
  JOIN student_group_load sgl ON sgl.group_id = sg.id
SET sg.update_import_id = sgl.import_id
WHERE sgl.import_id IS NOT NULL AND sgl.batch_id = 34;
##### TODO: transaction end

# trigger students migrate
UPDATE import i
  JOIN student_group_load_import sgli ON sgli.import_id = i.id
SET i.status = 1 -- or -1 if anything above failed
WHERE i.status = 0 AND sgli.batch_id = 34 AND sgli.ref_type IN (2, 3, 4, 5);
INSERT INTO batch_group_load_progress (batch_id, message) VALUE (34, 'update import id to migrate students');

# clean up
#  TODO: DELETE FROM student_group_load WHERE batch_id = 34;
#  TODO: DELETE FROM student_group_load_import WHERE batch_id = 34;

UPDATE batch_group_load_progress
SET message = 'done'
WHERE batch_id = 34;

# TODO: abandoned/not finished loads - use created timestamp and delete based on that?