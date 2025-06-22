-- Simple debug to see what's in your audit data
{{ config(materialized='table') }}

SELECT 
    kyc_profile_id,
    goldtier_id,
    cid,
    party_id,
    created_date,
    updated_date,
    op_type,
    op_time,
    -- Show ranking to see what should be latest
    ROW_NUMBER() OVER (PARTITION BY kyc_profile_id ORDER BY op_time DESC, updated_date DESC) as latest_rank
FROM {{ source('oriekyc', 'kyc_profile_audit') }}
ORDER BY kyc_profile_id, op_time
