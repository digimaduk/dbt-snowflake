-- Setup script for KYC Profile tables in Snowflake
-- Run this in your Snowflake console to create the source tables

-- Use your database and schema
USE DATABASE ORI_RAW_DB;
CREATE SCHEMA IF NOT EXISTS raw;
USE SCHEMA raw;

-- Create kyc_profile_audit table (source table with audit trail)
CREATE OR REPLACE TABLE kyc_profile_audit (
    kyc_profile_id NUMBER PRIMARY KEY,
    goldtier_id VARCHAR(50),
    cid VARCHAR(100),
    party_id VARCHAR(100),
    created_date TIMESTAMP_NTZ,
    updated_date TIMESTAMP_NTZ,
    op_type VARCHAR(10) NOT NULL,  -- INSERT, UPDATE, DELETE
    op_time TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Create kyc_profile table (target table for current state)
-- This will be managed by dbt, but we create it for reference
CREATE OR REPLACE TABLE kyc_profile (
    kyc_profile_id NUMBER PRIMARY KEY,
    goldtier_id VARCHAR(50),
    cid VARCHAR(100),
    party_id VARCHAR(100),
    created_date TIMESTAMP_NTZ,
    updated_date TIMESTAMP_NTZ
);

-- Insert sample audit data to demonstrate the pattern
-- Profile 1: Insert + 2 Updates
INSERT INTO kyc_profile_audit VALUES
(1, 'GOLD001', 'CID001', 'PARTY001', '2024-06-22 10:00:00', '2024-06-22 10:00:00', 'INSERT', '2024-06-22 10:00:00'),
(1, 'GOLD001', 'CID001', 'PARTY001', '2024-06-22 10:00:00', '2024-06-22 11:30:00', 'UPDATE', '2024-06-22 11:30:00'),
(1, 'GOLD002', 'CID001', 'PARTY001', '2024-06-22 10:00:00', '2024-06-22 14:15:00', 'UPDATE', '2024-06-22 14:15:00');

-- Profile 2: Insert + Update
INSERT INTO kyc_profile_audit VALUES
(2, 'GOLD003', 'CID002', 'PARTY002', '2024-06-22 09:30:00', '2024-06-22 09:30:00', 'INSERT', '2024-06-22 09:30:00'),
(2, 'GOLD003', 'CID002', 'PARTY002_UPDATED', '2024-06-22 09:30:00', '2024-06-22 12:45:00', 'UPDATE', '2024-06-22 12:45:00');

-- Profile 3: Insert only
INSERT INTO kyc_profile_audit VALUES
(3, 'GOLD004', 'CID003', 'PARTY003', '2024-06-22 08:00:00', '2024-06-22 08:00:00', 'INSERT', '2024-06-22 08:00:00');

-- Profile 4: Insert then Delete (should not appear in final table)
INSERT INTO kyc_profile_audit VALUES
(4, 'GOLD005', 'CID004', 'PARTY004', '2024-06-22 07:00:00', '2024-06-22 07:00:00', 'INSERT', '2024-06-22 07:00:00'),
(4, 'GOLD005', 'CID004', 'PARTY004', '2024-06-22 07:00:00', '2024-06-22 13:00:00', 'DELETE', '2024-06-22 13:00:00');

-- Profile 5: Recent changes (to test incremental behavior)
INSERT INTO kyc_profile_audit VALUES
(5, 'GOLD006', 'CID005', 'PARTY005', '2024-06-22 15:00:00', '2024-06-22 15:00:00', 'INSERT', '2024-06-22 15:00:00');

-- Verify the sample data
SELECT 'kyc_profile_audit sample data:' as info;
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
SELECT 'Expected profiles after sync:' as info;
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
WHERE rn = 1 AND op_type != 'DELETE'
ORDER BY kyc_profile_id;
