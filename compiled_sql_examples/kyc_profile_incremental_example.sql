-- This shows what the INCREMENTAL compiled SQL would look like
-- when the table already exists and dbt detects it should run incrementally

-- Advanced incremental model for kyc_profile sync
-- Handles INSERT, UPDATE, and DELETE operations from audit table
-- Designed to run every 10 minutes

-- ✅ INCREMENTAL MODE: This would be the SQL when running incrementally
-- The max_updated_date would be populated from the existing table

with audit_changes as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type,
        op_time,
        -- Rank records by op_time to get the latest operation per profile
        row_number() over (
            partition by kyc_profile_id 
            order by op_time desc, updated_date desc
        ) as latest_rank
    from ORI_RAW_DB.ORIEKYC.kyc_profile_audit
    
    -- 🔍 INCREMENTAL FILTER: Only processes changed profiles since last run
    where kyc_profile_id in (
        select distinct kyc_profile_id 
        from ORI_RAW_DB.ORIEKYC.kyc_profile_audit
        where op_time > '2024-06-22 14:15:00'  -- This would be the max updated_date from existing table
    )
),

latest_profile_state as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type
    from audit_changes
    where latest_rank = 1
),

-- Final dataset excluding deleted records
active_profiles as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date
    from latest_profile_state
    where op_type != 'D'  -- Exclude deleted profiles
)

select
    kyc_profile_id,
    goldtier_id,
    cid,
    party_id,
    created_date,
    updated_date
from active_profiles
