-- Add views to support filling in missing data in the aggregate reports.
-- Note that all views have the same structure so that they could be used interchangeably in the final query.
SET SEARCH_PATH to ${schemaName};

DROP VIEW state_subject_grade_school_year;
DROP VIEW school_subject_grade_school_year;
DROP VIEW district_subject_grade_school_year;

CREATE VIEW active_asmt(id, grade_id, school_year, subject_id, type_id) AS
(
    SELECT DISTINCT f.asmt_id as id,  f.asmt_grade_id AS grade_id, f.school_year,  asmt.subject_id, asmt.type_id FROM fact_student_exam f   JOIN asmt asmt ON asmt.id = f.asmt_id
    UNION
    SELECT id AS asmt_id, grade_id, school_year, subject_id, type_id FROM asmt
);

CREATE VIEW state_subject_grade_school_year(organization_id, organization_name, organization_type, subject_id, grade_id, school_year, asmt_id, asmt_type_id) AS
  SELECT
    -1          AS id,
    'State'     AS name,
    'State'     AS organization_type,
    s.id,
    g.id,
    year,
    a.id,
    a.type_id
  FROM subject s
    CROSS JOIN grade g
    CROSS JOIN school_year y
    JOIN active_asmt a  on a.grade_id = g.id and a.subject_id = s.id and a.school_year = y.year;


CREATE VIEW school_subject_grade_school_year(organization_id, organization_name, organization_type, subject_id, grade_id, school_year, asmt_id, asmt_type_id) AS
  SELECT
    sch.id,
    sch.name,
    'School' AS organization_type,
    s.id,
    g.id,
    year,
    a.id as asmt_id,
    a.type_id
  FROM school sch
    CROSS JOIN subject s
    CROSS JOIN grade g
    CROSS JOIN school_year y
    JOIN active_asmt a  on a.grade_id = g.id and a.subject_id = s.id and a.school_year = y.year;

CREATE VIEW district_subject_grade_school_year(organization_id, organization_name, organization_type, subject_id, grade_id, school_year, asmt_id, asmt_type_id) AS
  SELECT
    d.id,
    d.name,
    'District' AS organization_type,
    s.id,
    g.id,
    year,
    a.id as asmt_id,
    a.type_id
  FROM district d
    CROSS JOIN subject s
    CROSS JOIN grade g
    CROSS JOIN school_year y
    JOIN active_asmt a  on a.grade_id = g.id and a.subject_id = s.id and a.school_year = y.year;
