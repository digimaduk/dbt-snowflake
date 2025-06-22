-- Debug model to compare source vs target
{{ config(materialized='table') }}

SELECT 
    'kyc_profile_audit_source' as table_name,
    COUNT(*) as row_count,
    MIN(op_time) as min_op_time,
    MAX(op_time) as max_op_time,
    listagg(DISTINCT op_type, ',') as op_types_found
FROM {{ source('oriekyc', 'kyc_profile_audit') }}

UNION ALL

SELECT 
    'kyc_profile_target',
    COUNT(*),
    MIN(updated_date),
    MAX(updated_date),
    'N/A'
FROM {{ ref('kyc_profile') }}

UNION ALL

SELECT 
    'latest_non_deleted_profiles',
    COUNT(*),
    MIN(op_time),
    MAX(op_time),
    listagg(DISTINCT op_type, ',')
FROM (
    SELECT 
        kyc_profile_id,
        op_type,
        op_time,
        updated_date,
        ROW_NUMBER() OVER (PARTITION BY kyc_profile_id ORDER BY op_time DESC, updated_date DESC) as rn
    FROM {{ source('oriekyc', 'kyc_profile_audit') }}
) ranked
WHERE rn = 1 AND op_type != 'D'
