{% macro get_latest_audit_records(audit_table, profile_id_col, op_time_col, exclude_deletes=true) %}
  
  {%- set exclude_clause = "and op_type != 'DELETE'" if exclude_deletes else "" -%}
  
  with ranked_records as (
    select *,
      row_number() over (
        partition by {{ profile_id_col }}
        order by {{ op_time_col }} desc
      ) as rn
    from {{ audit_table }}
    where 1=1 {{ exclude_clause }}
  )
  select * from ranked_records where rn = 1

{% endmacro %}
