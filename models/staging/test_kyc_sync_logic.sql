-- Test model to demonstrate the KYC sync logic with sample data
-- Use this to test the concept before connecting to real tables

{{
  config(
    materialized='table'
  )
}}

-- Sample kyc_profile_audit data for testing
with sample_kyc_audit as (
    -- Profile 1: Insert + 2 Updates (latest should be goldtier_id = 'GOLD002')
    select 1 as kyc_profile_id, 'GOLD001' as goldtier_id, 'CID001' as cid, 'PARTY001' as party_id,
           '2024-06-22 10:00:00'::timestamp as created_date, '2024-06-22 10:00:00'::timestamp as updated_date,
           'INSERT' as op_type, '2024-06-22 10:00:00'::timestamp as op_time
    union all
    select 1, 'GOLD001', 'CID001', 'PARTY001',
           '2024-06-22 10:00:00'::timestamp, '2024-06-22 11:30:00'::timestamp,
           'UPDATE', '2024-06-22 11:30:00'::timestamp
    union all
    select 1, 'GOLD002', 'CID001', 'PARTY001',
           '2024-06-22 10:00:00'::timestamp, '2024-06-22 14:15:00'::timestamp,
           'UPDATE', '2024-06-22 14:15:00'::timestamp
           
    -- Profile 2: Insert + Update (latest should be party_id = 'PARTY002_UPDATED')
    union all
    select 2, 'GOLD003', 'CID002', 'PARTY002',
           '2024-06-22 09:30:00'::timestamp, '2024-06-22 09:30:00'::timestamp,
           'INSERT', '2024-06-22 09:30:00'::timestamp
    union all
    select 2, 'GOLD003', 'CID002', 'PARTY002_UPDATED',
           '2024-06-22 09:30:00'::timestamp, '2024-06-22 12:45:00'::timestamp,
           'UPDATE', '2024-06-22 12:45:00'::timestamp
           
    -- Profile 3: Insert only
    union all
    select 3, 'GOLD004', 'CID003', 'PARTY003',
           '2024-06-22 08:00:00'::timestamp, '2024-06-22 08:00:00'::timestamp,
           'INSERT', '2024-06-22 08:00:00'::timestamp
           
    -- Profile 4: Insert then Delete (should NOT appear in result)
    union all
    select 4, 'GOLD005', 'CID004', 'PARTY004',
           '2024-06-22 07:00:00'::timestamp, '2024-06-22 07:00:00'::timestamp,
           'INSERT', '2024-06-22 07:00:00'::timestamp
    union all
    select 4, 'GOLD005', 'CID004', 'PARTY004',
           '2024-06-22 07:00:00'::timestamp, '2024-06-22 13:00:00'::timestamp,
           'DELETE', '2024-06-22 13:00:00'::timestamp
),

-- Apply the same logic as the main model
latest_audit_records as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type,
        op_time,
        row_number() over (
            partition by kyc_profile_id 
            order by op_time desc, updated_date desc
        ) as latest_rank
    from sample_kyc_audit
),

current_state as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type
    from latest_audit_records
    where latest_rank = 1
),

-- Final result excluding deleted records
active_profiles as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date
    from current_state
    where op_type != 'DELETE'  -- Exclude deleted profiles
)

select
    kyc_profile_id,
    goldtier_id,
    cid,
    party_id,
    created_date,
    updated_date
from active_profiles
order by kyc_profile_id
