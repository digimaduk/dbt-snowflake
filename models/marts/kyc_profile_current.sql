{{
  config(
    materialized='incremental',
    unique_key='kyc_profile_id',
    on_schema_change='fail',
    incremental_strategy='delete+insert',
    pre_hook="{{ log('Starting kyc_profile sync from audit table at ' ~ run_started_at, info=true) }}"
  )
}}

-- Advanced incremental model for kyc_profile sync
-- Handles INSERT, UPDATE, and DELETE operations from audit table
-- Designed to run every 10 minutes

{% if is_incremental() %}
  {% set max_updated_date_query %}
    select coalesce(max(updated_date), '1900-01-01'::timestamp) as max_date
    from {{ this }}
  {% endset %}
  
  {% set results = run_query(max_updated_date_query) %}
  {% if execute %}
    {% set max_updated_date = results.columns[0].values()[0] %}
  {% else %}
    {% set max_updated_date = '1900-01-01' %}
  {% endif %}
{% endif %}

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
    from {{ source('raw', 'kyc_profile_audit') }}
    
    {% if is_incremental() %}
        -- Only process profiles that have had changes since last run
        where kyc_profile_id in (
            select distinct kyc_profile_id 
            from {{ source('raw', 'kyc_profile_audit') }}
            where op_time > '{{ max_updated_date }}'
        )
    {% endif %}
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
