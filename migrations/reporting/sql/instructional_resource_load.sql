-- SAMPLE insertion of assessment-wide System instructional resources.
-- Modify this sample script to insert assessment-wide or performance-level
--  instructional resources for the system.
--
-- These URLs were provided by SmarterBalanced on or about 2017/12/12.

use reporting;

DELETE FROM instructional_resource;

INSERT INTO instructional_resource (asmt_name, org_level, performance_level, resource) VALUES
  ('SBAC-IAB-FIXED-G3E-BriefWrites-ELA-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-brief-writes'),
  ('SBAC-IAB-FIXED-G3E-ReadInfo-ELA-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-reading-informational-texts'),
  ('SBAC-IAB-FIXED-G3E-ReadLit-ELA-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-reading-literary-text'),
  ('SBAC-IAB-FIXED-G3E-Revision-ELA-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-revision'),
  ('SBAC-IAB-FIXED-G4E-BriefWrites-ELA-4', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-4-brief-writes'),
  ('SBAC-IAB-FIXED-G4E-ReadInfo-ELA-4', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-4-read-informational-text'),
  ('SBAC-IAB-FIXED-G4E-ReadLit-ELA-4', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-4-read-literary-texts'),
  ('SBAC-IAB-FIXED-G4E-Revision-ELA-4', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-4-revision'),
  ('SBAC-IAB-FIXED-G5E-BriefWrites-ELA-5', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-5-brief-writes'),
  ('SBAC-IAB-FIXED-G5E-ReadInfo-ELA-5', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-5-read-informational-texts'),
  ('SBAC-IAB-FIXED-G5E-ReadLit-ELA-5', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-5-read-literary-texts'),
  ('SBAC-IAB-FIXED-G6E-BriefWrites-ELA-6', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-6-brief-writes'),
  ('SBAC-IAB-FIXED-G6E-ReadInfo-ELA-6', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-6-read-informational-texts'),
  ('SBAC-IAB-FIXED-G6E-ReadLit-ELA-6', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-6-read-literary-texts'),
  ('SBAC-IAB-FIXED-G7E-BriefWrites-ELA-7', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-7-brief-writes'),
  ('SBAC-IAB-FIXED-G7E-ReadInfo-ELA-7', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-7-read-informational-texts'),
  ('SBAC-IAB-FIXED-G7E-ReadLit-ELA-7', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-7-read-literary-texts'),
  ('SBAC-IAB-FIXED-G8E-BriefWrites-ELA-8', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-brief-writes'),
  ('SBAC-IAB-FIXED-G8E-Perf-Explanatory-CompareAncient', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-performance-task'),
  ('SBAC-IAB-FIXED-G8E-ReadInfo-ELA-8', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-read-informational-texts'),
  ('SBAC-IAB-FIXED-G8E-ReadLit-ELA-8', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-read-literary-texts'),
  ('SBAC-IAB-FIXED-G8E-Research-ELA-8', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-research'),
  ('SBAC-IAB-FIXED-G11E-BriefWrites-ELA-11', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-high-school-brief-writes'),
  ('SBAC-IAB-FIXED-G11E-ReadInfo-ELA-11', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-hs-read-informational-texts'),
  ('SBAC-IAB-FIXED-G11E-ReadLit-ELA-11', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-hs-read-literary-texts'),
  ('SBAC-IAB-FIXED-G11E-Revision-ELA-11', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-high-school-revision'),
  ('SBAC-IAB-FIXED-G3M-NF-MATH-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-fractions-0'),
  ('SBAC-IAB-FIXED-G3M-NBT-MATH-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-number-and-operations-base-ten'),
  ('SBAC-IAB-FIXED-G3M-OA-MATH-3', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-3-operations-and-algebraic-thinking'),
  ('SBAC-IAB-FIXED-G4M-NF-MATH-4', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-4-fractions'),
  ('SBAC-IAB-FIXED-G4M-OA-MATH-4', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-4-operations-and-algebraic-thinking'),
  ('SBAC-IAB-FIXED-G5M-NF-MATH-5', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-5-fractions'),
  ('SBAC-IAB-FIXED-G5M-MD-MATH-5', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-5-measurement-and-data'),
  ('SBAC-IAB-FIXED-G5M-NBT-MATH-5', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-5-numbers-and-operations-base-ten'),
  ('SBAC-IAB-FIXED-G6M-G-Calc-MATH-6', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-6-geometry'),
  ('SBAC-IAB-FIXED-G6M-RP', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-6-ratios-and-proportional-reasoning'),
  ('SBAC-IAB-FIXED-G6M-NS', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-6-number-system'),
  ('SBAC-IAB-FIXED-G7M-EE', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-7-expressions-and-equations'),
  ('SBAC-IAB-FIXED-G7M-G', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-7-geometry'),
  ('SBAC-IAB-FIXED-G7M-RP-Calc-MATH-7', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-7-ratio-and-proportion'),
  ('SBAC-IAB-FIXED-G8M-EE', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-expressions-and-equations-i'),
  ('SBAC-IAB-FIXED-G8M-EE2-Calc-MATH-8', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-grade-8-expressions-and-equations-ii'),
  ('SBAC-IAB-FIXED-G11M-AlgLin', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-high-school-algebra-and-functions-i'),
  ('SBAC-IAB-FIXED-G11M-AlgQuad', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-high-school-algebra-and-functions-ii'),
  ('SBAC-IAB-FIXED-G11M-SP-Calc-MATH-11', 'System', 0, 'https://www.smarterbalancedlibrary.org/content/smarter-balanced-connections-playlist-high-school-statistics-and-probability');
