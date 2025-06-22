-- Setup script for KYC Profile tables in your ORIEKYC schema
-- Run this in your Snowflake console to create the source table with sample data

-- Use your existing database and schema
USE DATABASE ORI_RAW_DB;
USE SCHEMA ORIEKYC;

-- Create kyc_profile_audit table (source table with audit trail)
CREATE OR REPLACE TABLE kyc_profile_audit (
    kyc_profile_id NUMBER,
    goldtier_id VARCHAR(50),
    cid VARCHAR(100),
    party_id VARCHAR(100),
    created_date TIMESTAMP_NTZ,
    updated_date TIMESTAMP_NTZ,
    op_type VARCHAR(1) NOT NULL,  -- I=INSERT, U=UPDATE, D=DELETE
    op_time TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample audit data to test the dbt model
-- Profile 1: Insert + 2 Updates (latest should have goldtier_id = 'GOLD002')
INSERT INTO kyc_profile_audit VALUES
(1, 'GOLD001', 'CID001', 'PARTY001', '2024-06-22 10:00:00', '2024-06-22 10:00:00', 'I', '2024-06-22 10:00:00'),
(1, 'GOLD001', 'CID001', 'PARTY001', '2024-06-22 10:00:00', '2024-06-22 11:30:00', 'U', '2024-06-22 11:30:00'),
(1, 'GOLD002', 'CID001', 'PARTY001', '2024-06-22 10:00:00', '2024-06-22 14:15:00', 'U', '2024-06-22 14:15:00');

-- Profile 2: Insert + Update (latest should have party_id = 'PARTY002_UPDATED')
INSERT INTO kyc_profile_audit VALUES
(2, 'GOLD003', 'CID002', 'PARTY002', '2024-06-22 09:30:00', '2024-06-22 09:30:00', 'I', '2024-06-22 09:30:00'),
(2, 'GOLD003', 'CID002', 'PARTY002_UPDATED', '2024-06-22 09:30:00', '2024-06-22 12:45:00', 'U', '2024-06-22 12:45:00');

-- Profile 3: Insert only
INSERT INTO kyc_profile_audit VALUES
(3, 'GOLD004', 'CID003', 'PARTY003', '2024-06-22 08:00:00', '2024-06-22 08:00:00', 'I', '2024-06-22 08:00:00');

-- Profile 4: Insert then Delete (should NOT appear in final result)
INSERT INTO kyc_profile_audit VALUES
(4, 'GOLD005', 'CID004', 'PARTY004', '2024-06-22 07:00:00', '2024-06-22 07:00:00', 'I', '2024-06-22 07:00:00'),
(4, 'GOLD005', 'CID004', 'PARTY004', '2024-06-22 07:00:00', '2024-06-22 13:00:00', 'D', '2024-06-22 13:00:00');

-- Profile 5: Recent changes (to test incremental behavior)
INSERT INTO kyc_profile_audit VALUES
(5, 'GOLD006', 'CID005', 'PARTY005', '2024-06-22 15:00:00', '2024-06-22 15:00:00', 'I', '2024-06-22 15:00:00');

-- Verify the sample data
SELECT 'kyc_profile_audit total rows:' as info, COUNT(*) as count FROM kyc_profile_audit;

SELECT 
    kyc_profile_id,
    goldtier_id,
    cid,
    party_id,
    op_type,
    op_time,
    -- Show which record is latest for each profile
    row_number() over (partition by kyc_profile_id order by op_time desc) as latest_rank
FROM kyc_profile_audit 
ORDER BY kyc_profile_id, op_time;

-- Expected result after dbt sync: 4 active profiles (profile 4 deleted)
SELECT 'Expected profiles after dbt sync:' as info;
WITH latest_records AS (
    SELECT *,
        row_number() over (partition by kyc_profile_id order by op_time desc) as rn
    FROM kyc_profile_audit
)
SELECT 
    kyc_profile_id,
    goldtier_id,
    cid,
    party_id,
    created_date,
    updated_date
FROM latest_records 
WHERE rn = 1 AND op_type != 'D'
ORDER BY kyc_profile_id;
