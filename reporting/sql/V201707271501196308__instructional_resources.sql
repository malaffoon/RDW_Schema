-- original source is : http://www.smarterbalanced.org/educators/the-digital-library/

USE ${schemaName};

TRUNCATE instructional_resource;
ALTER table instructional_resource DROP COLUMN id;
ALTER table instructional_resource ADD COLUMN name varchar(250) NOT NULL PRIMARY KEY;

INSERT INTO instructional_resource (name, resource) VALUES
 ('SBAC-IAB-FIXED-G3M-NBT-MATH-3', 'https://portal.smarterbalanced.org/library/en/v1.0/digital-library-connections-grade-3-number-and-operations-in-base-ten.docx'),
 ('SBAC-IAB-FIXED-G4E-Revision-ELA-4', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-4-revision.docx'),
 ('SBAC-IAB-FIXED-G4E-BriefWrites-ELA-4', 'https://portal.smarterbalanced.org/library/en/v1.0/digital-library-connections-grade-4-brief-writes.docx'),
 ('SBAC-IAB-FIXED-G5M-NF-MATH-5', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-5-fractions.docx'),
 ('SBAC-IAB-FIXED-G6M-G-Calc-MATH-6', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-6-geometry.docx'),
 ('SBAC-IAB-FIXED-G7E-ReadLit-ELA-7', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-7-read-literary-texts.docx'),
 ('SBAC-IAB-FIXED-G7M-RP-Calc-MATH-7', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-7-ratio-and-proportional-relationships.docx'),
 ('SBAC-IAB-FIXED-G8E-Research-ELA-8', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-grade-8-research.docx'),
 ('SBAC-IAB-FIXED-G11E-BriefWrites-ELA-11','https://portal.smarterbalanced.org/library/en/digital-library-connections-high-school-brief-writes.docx'),
 ('SBAC-IAB-FIXED-G11E-Revision-ELA-11', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-high-school-revision.docx'),
 ('SBAC-IAB-FIXED-G11M-SP-Calc-MATH-11', 'https://portal.smarterbalanced.org/library/en/digital-library-connections-high-school-statistics-and-probability.docx');