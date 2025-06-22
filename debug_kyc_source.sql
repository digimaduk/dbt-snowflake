-- Debug query to check what's in the source table
-- Run this in Snowflake to see if data exists

-- Check if the audit table exists and has data
SELECT 'kyc_profile_audit' as table_name, COUNT(*) as row_count 
FROM ORI_RAW_DB.ORIEKYC.kyc_profile_audit;

-- Show sample data from audit table
SELECT * FROM ORI_RAW_DB.ORIEKYC.kyc_profile_audit LIMIT 10;

-- Check what our model would produce
WITH audit_changes as (
    SELECT
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type,
        op_time,
        row_number() OVER (
            PARTITION BY kyc_profile_id 
            ORDER BY op_time DESC, updated_date DESC
        ) as latest_rank
    FROM ORI_RAW_DB.ORIEKYC.kyc_profile_audit
),
latest_profile_state as (
    SELECT
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type
    FROM audit_changes
    WHERE latest_rank = 1
),
active_profiles as (
    SELECT
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date
    FROM latest_profile_state
    WHERE op_type != 'D'  -- Exclude deleted profiles
)
SELECT 'Expected output' as info, COUNT(*) as expected_rows FROM active_profiles
UNION ALL
SELECT 'Sample data', NULL FROM (SELECT 1 LIMIT 0);

-- Show the actual expected output
WITH audit_changes as (
    SELECT
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type,
        op_time,
        row_number() OVER (
            PARTITION BY kyc_profile_id 
            ORDER BY op_time DESC, updated_date DESC
        ) as latest_rank
    FROM ORI_RAW_DB.ORIEKYC.kyc_profile_audit
),
latest_profile_state as (
    SELECT
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type
    FROM audit_changes
    WHERE latest_rank = 1
),
active_profiles as (
    SELECT
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date
    FROM latest_profile_state
    WHERE op_type != 'D'  -- Exclude deleted profiles
)
SELECT * FROM active_profiles;
