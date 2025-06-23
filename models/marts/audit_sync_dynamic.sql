{{
  config(
    materialized='incremental',
    unique_key=var('audit_sync_configs')[var('sync_table')]['unique_key'],
    on_schema_change='fail',
    incremental_strategy='merge',
    pre_hook="{{ log('Starting dynamic audit sync for ' ~ var('sync_table') ~ ' at ' ~ run_started_at, info=true) }}",
    alias=var('audit_sync_configs')[var('sync_table')]['target_table']
  )
}}

-- Dynamic audit sync model - single model for all audit table syncs
-- Usage: dbt run --models audit_sync_dynamic --vars "sync_table: kyc_profile"
-- Usage: dbt run --models audit_sync_dynamic --vars "sync_table: kyc_profile_stg"

{% set sync_table = var('sync_table', '') %}

{% if sync_table == '' %}
  {{ exceptions.raise_compiler_error("sync_table variable is required. Use: dbt run --models audit_sync_dynamic --vars \"sync_table: your_table\"") }}
{% endif %}

{% if sync_table not in var('audit_sync_configs') %}
  {{ exceptions.raise_compiler_error("sync_table '" ~ sync_table ~ "' not found in audit_sync_configs. Available configs: " ~ var('audit_sync_configs').keys() | list) }}
{% endif %}

{{ log('Processing sync for: ' ~ sync_table, info=true) }}

{{ audit_sync_model(sync_table) }}
