-- add views to support filling in missing data in the aggregate reports

SET SEARCH_PATH to ${schemaName};

CREATE VIEW state_subject_grade_school_year(organization_id, organization_name, organization_type, subject_id, grade_id, school_year, asmt_id, asmt_type_id) AS
  SELECT
    -1          AS id,
    'state'     AS name,
    'state'     AS organization_type,
    s.id,
    g.id,
    year,
    a.id as asmt_id,
    a.type_id
  FROM subject s
    CROSS JOIN grade g
      JOIN asmt a on a.grade_id = g.id and a.subject_id = s.id
    CROSS JOIN school_year y;

CREATE VIEW school_subject_grade_school_year(organization_id, organization_name, organization_type, subject_id, grade_id, school_year, asmt_id, asmt_type_id) AS
  SELECT
    sch.id,
    sch.name,
    'school' AS organization_type,
    s.id,
    g.id,
    year,
    a.id as asmt_id,
    a.type_id
  FROM school sch
    CROSS JOIN subject s
    CROSS JOIN grade g
     JOIN asmt a on a.grade_id = g.id and a.subject_id = s.id
    CROSS JOIN school_year y;

CREATE VIEW district_subject_grade_school_year(organization_id, organization_name, organization_type, subject_id, grade_id, school_year, asmt_id, asmt_type_id) AS
  SELECT
    d.id,
    d.name,
    'district' AS organization_type,
    s.id,
    g.id,
    year,
    a.id as asmt_id,
    a.type_id
  FROM district d
    CROSS JOIN subject s
    CROSS JOIN grade g
     JOIN asmt a on a.grade_id = g.id and a.subject_id = s.id
    CROSS JOIN school_year y;