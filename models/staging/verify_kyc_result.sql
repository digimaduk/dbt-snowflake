-- Simple verification query
{{ config(materialized='table') }}

SELECT 
    'kyc_profile_result' as check_type,
    COUNT(*) as row_count,
    COALESCE(kyc_profile_id::VARCHAR, 'NO_DATA') as profile_id,
    COALESCE(goldtier_id, 'NO_DATA') as goldtier,
    'N/A' as original_op_type
FROM {{ ref('kyc_profile') }}
GROUP BY ALL

UNION ALL

SELECT 
    'source_data_check',
    COUNT(*),
    kyc_profile_id::VARCHAR,
    goldtier_id,
    op_type
FROM {{ source('oriekyc', 'kyc_profile_audit') }}
WHERE op_type = 'I'
GROUP BY ALL
