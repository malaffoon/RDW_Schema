SELECT school_year, count(*) AS count
FROM student_group
WHERE deleted = 0 and active = 1
GROUP BY school_year;
