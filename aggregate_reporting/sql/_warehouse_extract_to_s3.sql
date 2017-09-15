-- observations
-- null pointer exception happens when called via IntelliJ
-- when called from mysql prompt - works fine but sometimes I am getting file alreddy exists, turn overwrite on
-- execution times:
--    - student -- Query OK, 710846 rows affected (4.91 sec)
--    - exam_student - Query OK, 25432787 rows affected (1 min 24.61 sec)
--    - exam -- Query OK, 25432787 rows affected (3 min 8.76 sec)
--    - exam_claim_score -- Query OK, 4264132 rows affected (13.03 sec)

SELECT
  id,
  code
FROM warehouse.subject
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/subject'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  code,
  name
FROM warehouse.grade
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/grade'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  code,
  name
FROM warehouse.asmt_type
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/asmt_type'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  code
FROM warehouse.completeness
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/completeness'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  code
FROM warehouse.administration_condition
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/administration_condition'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  code
FROM warehouse.ethnicity
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/ethnicity'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  code
FROM warehouse.gender
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/gender'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT year
FROM warehouse.school_year
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/school_year'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  natural_id,
  grade_id,
  type_id,
  subject_id,
  school_year,
  name
FROM warehouse.asmt
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/asmt'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  subject_id,
  asmt_type_id,
  code,
  name
FROM warehouse.subject_claim_score
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/subject_claim_score'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  natural_id,
  name
FROM warehouse.district
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/district'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  district_id,
  natural_id,
  name
FROM warehouse.school
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/school'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  ssid,
  last_or_surname,
  first_name,
  middle_name,
  gender_id
FROM warehouse.student
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/student'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  ethnicity_id,
  student_id
FROM warehouse.student_ethnicity
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/student_ethnicity'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  grade_id,
  student_id,
  school_id,
  iep,
  lep,
  section504,
  economic_disadvantage,
  migrant_status
FROM warehouse.exam_student
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/exam_student'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  type_id,
  exam_student_id,
  school_year,
  asmt_id,
  completeness_id,
  administration_condition_id,
  scale_score,
  scale_score_std_err,
  performance_level,
  completed_at
FROM warehouse.exam
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/exam'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

SELECT
  id,
  exam_id,
  subject_claim_score_id,
  scale_score,
  scale_score_std_err
FROM warehouse.exam_claim_score
INTO OUTFILE S3 's3-us-west-2://rdw-dev-archive/REDSHIFT_EXTRACT/exam_claim_score'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';

