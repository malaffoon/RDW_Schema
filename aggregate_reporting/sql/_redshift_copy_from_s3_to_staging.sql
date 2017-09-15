-- TODO: read the best practices and decide what is the best for us
-- there are options of parallel loading multiple files and file compression

-- To verify the load check STL_LOAD_COMMITS table
-- Replace '<your aws_iam_role here> with the appropriate role, example: 'aws_iam_role=arn:aws:iam::99911177755:role/rdw-redshift'

COPY dev.reporting.staging_subject (id, code)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/subject.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
--  completed in 1s 714ms

COPY dev.reporting.staging_grade (id, code, NAME)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/grade.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 1s 867ms

COPY dev.reporting.staging_asmt_type(id,code,name)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/asmt_type.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 9s 64ms

COPY dev.reporting.staging_completeness(id, code)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/completeness.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 4s 625ms

COPY dev.reporting.staging_administration_condition(id, code)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/administration_condition.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 5s 811ms

COPY dev.reporting.staging_ethnicity(id, code)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/ethnicity.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_gender(id, code)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/gender.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_school_year(year)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/school_year.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_asmt(
  id,
  natural_id,
  grade_id,
  type_id,
  subject_id,
  school_year,
  name)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/asmt.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 20s 636ms

COPY dev.reporting.staging_subject_claim_score(
  id,
  subject_id,
  asmt_type_id,
  code,
  name)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/subject_claim_score.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_district(
  id,
  natural_id,
  name)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/district.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_school(
  id,
  district_id,
  natural_id,
  name)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/school.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_student(
  id,
  ssid,
  last_or_surname,
  first_name,
  middle_name,
  gender_id)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/student.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 24s 884ms

COPY dev.reporting.staging_student_ethnicity(
  ethnicity_id,
  student_id)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/student_ethnicity.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';

COPY dev.reporting.staging_exam_student(
  id,
  grade_id,
  student_id,
  school_id,
  iep,
  lep,
  section504,
  economic_disadvantage,
  migrant_status)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/exam_student.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 1m 12s 471ms

COPY dev.reporting.staging_exam(
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
  completed_at)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/exam.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 1m 55s 397ms

COPY dev.reporting.staging_exam_claim_score(
  id,
  exam_id,
  subject_claim_score_id,
  scale_score,
  scale_score_std_err)
FROM 's3://rdw-dev-archive/REDSHIFT_EXTRACT/exam_claim_score.part_00000'
CREDENTIALS '<your aws_iam_role here>'
FORMAT AS CSV
DELIMITER ',';
-- completed in 26s 196ms