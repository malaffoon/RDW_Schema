USE ${schemaName};

/*
Create records with effective embargo for ALL districts regardless of timestamps. The
truth table for how state and district setting resolve to the effective setting is a bit
non-obvious. Recall that state=FALSE trumps district setting, "default" for individual
embargo is FALSE and "default" for aggregate embargo is TRUE:

             (individual)  (aggregate)
    district  T   F  null   T   F  null
             -----------   -----------
 state T    | T | F | T |  | T | F | T |
       F    | F | F | F |  | F | F | F |
       null | T | F | F |  | T | F | T |
             -----------    -----------
*/
CREATE VIEW embargo AS
  SELECT
    d.id AS district_id,
    de.school_year,
    IF(se.individual = 0 OR de.individual = 0 OR (se.individual IS NULL AND de.individual IS NULL), 0, 1) AS individual,
    IF(se.aggregate = 0 OR de.aggregate = 0, 0, 1) AS aggregate
  FROM district d
    LEFT JOIN district_embargo de ON de.district_id = d.id
    LEFT JOIN state_embargo se ON se.school_year = de.school_year;