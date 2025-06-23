-- Configurable audit sync macro
-- Generates incremental sync logic based on configuration

{% macro audit_sync_model(config_name) %}
  
  -- Load configuration from dbt_project.yml vars or default config
  {% set config = var('audit_sync_configs', {})[config_name] %}
  
  {% if not config %}
    {{ exceptions.raise_compiler_error("Configuration not found for: " ~ config_name) }}
  {% endif %}
  
  {% set source_table = config.get('source_table') %}
  {% set target_table = config.get('target_table') %}
  {% set unique_key = config.get('unique_key') %}
  
  -- Auto-discover columns from target table schema
  -- This ensures we only select columns that actually exist in the target
  {% set columns_query %}
    select column_name
    from information_schema.columns 
    where table_schema = '{{ target.schema }}'
    and table_name = upper('{{ target_table }}')
    order by ordinal_position
  {% endset %}
  
  {% if execute %}
    {% set results = run_query(columns_query) %}
    {% set columns = results.columns[0].values() %}
    {{ log('Auto-discovered columns from target table ' ~ target_table ~ ': ' ~ columns | join(', '), info=true) }}
  {% else %}
    {% set columns = ['*'] %}
  {% endif %}
  
  -- Generate incremental logic
  {% if is_incremental() %}
    {% set max_updated_date_query %}
      select coalesce(max(updated_date), '1900-01-01'::timestamp) as max_date
      from {{ target.schema }}.{{ target_table }}
    {% endset %}
    
    {% set results = run_query(max_updated_date_query) %}
    {% if execute %}
      {% set max_updated_date = results.columns[0].values()[0] %}
      {{ log('Incremental mode for ' ~ target_table ~ ': max_updated_date = ' ~ max_updated_date, info=true) }}
    {% else %}
      {% set max_updated_date = '1900-01-01' %}
    {% endif %}
  {% else %}
    {{ log('Full refresh mode for ' ~ target_table ~ ': processing all records', info=true) }}
  {% endif %}

  -- Generate the SQL - get latest state for each unique key
  with audit_changes as (
    select
      {{ columns | join(',\n      ') }},
      op_type,
      op_time,
      -- Rank records by op_time to get the latest operation per profile
      row_number() over (
        partition by {{ unique_key }}
        order by op_time desc, updated_date desc
      ) as latest_rank
    from {{ source('oriekyc', source_table) }}
    
    {% if is_incremental() %}
      -- Only process profiles that have had changes since last run
      where op_time > '{{ max_updated_date }}'
    {% endif %}
  )

  -- Return latest states directly
  select
    {{ columns | join(',\n    ') }}
  from audit_changes
  where latest_rank = 1

{% endmacro %}
