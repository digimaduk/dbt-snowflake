{{
  config(
    materialized='incremental',
    unique_key='kyc_profile_id',
    on_schema_change='fail',
    incremental_strategy='merge'
  )
}}

-- Incremental model to sync latest records from kyc_profile_audit to kyc_profile
-- Runs every 10 minutes to capture the most recent state of each profile

with latest_audit_records as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date,
        op_type,
        op_time,
        -- Get the latest record for each kyc_profile_id based on op_time
        row_number() over (
            partition by kyc_profile_id 
            order by op_time desc
        ) as rn
    from {{ source('oriekyc', 'kyc_profile_audit') }}
    
    {% if is_incremental() %}
        -- Only process records that have been modified since last run
        -- This looks at op_time to find new audit entries
        where op_time > (select max(updated_date) from {{ this }})
    {% endif %}
),

current_state as (
    select
        kyc_profile_id,
        goldtier_id,
        cid,
        party_id,
        created_date,
        updated_date
    from latest_audit_records
    where rn = 1  -- Only the latest record for each profile
      and op_type != 'DELETE'  -- Exclude deleted records
)

select
    kyc_profile_id,
    goldtier_id,
    cid,
    party_id,
    created_date,
    updated_date
from current_state
