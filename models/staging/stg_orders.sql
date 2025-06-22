{{
  config(
    materialized='view'
  )
}}

-- Example staging model for raw orders data

select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,
    created_at,
    updated_at
from {{ source('raw', 'orders') }}
