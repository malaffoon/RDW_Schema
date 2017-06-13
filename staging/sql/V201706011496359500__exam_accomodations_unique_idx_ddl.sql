/**
* DWR-449 Performance improvement.
**/

USE ${schemaName};

-- With this index we can do INSERT IGNORE to remove duplicates
CREATE UNIQUE INDEX uk__exam_available_accommodation ON staging_exam_available_accommodation (exam_id, accommodation_id);

