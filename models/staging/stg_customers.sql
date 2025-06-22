{{
  config(
    materialized='view'
  )
}}

-- Example staging model for raw customer data
-- This would typically read from your raw Snowflake tables

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    state,
    zip_code,
    created_at,
    updated_at
from {{ source('raw', 'customers') }}
