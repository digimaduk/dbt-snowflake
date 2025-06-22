-- Simple model to check if the source table has data
{{ config(materialized='table') }}

SELECT 
    'source_audit_count' as check_type,
    COUNT(*) as row_count
FROM {{ source('oriekyc', 'kyc_profile_audit') }}

UNION ALL

SELECT 
    'distinct_profiles' as check_type,
    COUNT(DISTINCT kyc_profile_id) as row_count
FROM {{ source('oriekyc', 'kyc_profile_audit') }}

UNION ALL

SELECT 
    'non_deleted_latest' as check_type,
    COUNT(*) as row_count
FROM (
    SELECT 
        kyc_profile_id,
        op_type,
        ROW_NUMBER() OVER (PARTITION BY kyc_profile_id ORDER BY op_time DESC, updated_date DESC) as rn
    FROM {{ source('oriekyc', 'kyc_profile_audit') }}
) ranked
WHERE rn = 1 AND op_type != 'D'
