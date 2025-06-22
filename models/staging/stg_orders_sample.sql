{{
  config(
    materialized='view'
  )
}}

-- Example staging model using sample order data

with sample_orders as (
    select 
        1 as order_id,
        1 as customer_id,
        '2024-01-15'::date as order_date,
        'completed' as status,
        150.00 as total_amount,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    union all
    select 
        2, 2, '2024-01-16'::date, 'completed', 89.99,
        current_timestamp(), current_timestamp()
    union all
    select 
        3, 1, '2024-01-20'::date, 'completed', 200.50,
        current_timestamp(), current_timestamp()
    union all
    select 
        4, 3, '2024-01-22'::date, 'pending', 75.25,
        current_timestamp(), current_timestamp()
)

select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,
    created_at,
    updated_at
from sample_orders
