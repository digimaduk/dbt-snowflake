-- Test to verify your actual data structure
{{ config(materialized='table') }}

SELECT 
    'Step 1: Raw audit data' as step,
    kyc_profile_id,
    op_type,
    op_time,
    updated_date,
    'N/A' as latest_rank
FROM {{ source('oriekyc', 'kyc_profile_audit') }}

UNION ALL

SELECT 
    'Step 2: With ranking' as step,
    kyc_profile_id,
    op_type,
    op_time,
    updated_date,
    latest_rank::varchar
FROM (
    SELECT 
        kyc_profile_id,
        op_type,
        op_time,
        updated_date,
        ROW_NUMBER() OVER (PARTITION BY kyc_profile_id ORDER BY op_time DESC, updated_date DESC) as latest_rank
    FROM {{ source('oriekyc', 'kyc_profile_audit') }}
) ranked

UNION ALL

SELECT 
    'Step 3: Latest non-deleted' as step,
    kyc_profile_id,
    op_type,
    op_time,
    updated_date,
    'FINAL'
FROM (
    SELECT 
        kyc_profile_id,
        op_type,
        op_time,
        updated_date,
        ROW_NUMBER() OVER (PARTITION BY kyc_profile_id ORDER BY op_time DESC, updated_date DESC) as latest_rank
    FROM {{ source('oriekyc', 'kyc_profile_audit') }}
) ranked
WHERE latest_rank = 1 AND op_type NOT IN ('D', 'DELETE', 'Del')

ORDER BY step, kyc_profile_id, op_time
