-- loads data AFTER asmts have been loaded into reporting
-- original source is : http://www.smarterbalanced.org/educators/the-digital-library/

INSERT IGNORE INTO reporting.instructional_resource (id, resource)
SELECT id, 'https://portal.smarterbalanced.org/library/en/v1.0/digital-library-connections-grade-3-number-and-operations-in-base-ten.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 03 Math - Number and Operations in Base Ten (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-4-revision.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 04 ELA - Revision (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/v1.0/digital-library-connections-grade-4-brief-writes.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 04 ELA - Brief Writes (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-5-fractions.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 05 Math - Number and Operations - Fractions (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-6-geometry.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 06 Math - Geometry (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-7-read-literary-texts.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 07 ELA - Read Literary Texts (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-7-ratio-and-proportional-relationships.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 07 Math - Ratios and Proportional Relationships (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-8-research.docx' AS resource FROM reporting.asmt WHERE label = 'Grade 08 ELA - Research (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-high-school-brief-writes.docx' AS resource FROM reporting.asmt WHERE label = 'High School ELA - Brief Writes (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-high-school-revision.docx' AS resource FROM reporting.asmt WHERE label = 'High School ELA - Revision (IAB)'
UNION ALL
SELECT id, 'https://portal.smarterbalanced.org/library/en/digital-library-connections-high-school-statistics-and-probability.docx' AS resource FROM reporting.asmt WHERE label = 'High School Math - Statistics and Probability (IAB)'