{{
  config(
    materialized='table'
  )
}}

-- Example mart model that combines customer and order data

with customer_orders as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.city,
        c.state,
        count(o.order_id) as total_orders,
        sum(o.total_amount) as total_spent,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date
    from {{ ref('stg_customers') }} c
    left join {{ ref('stg_orders') }} o
        on c.customer_id = o.customer_id
    group by 1, 2, 3, 4, 5, 6
)

select
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    total_orders,
    total_spent,
    case 
        when total_orders = 0 then 'Never Ordered'
        when total_orders = 1 then 'One-time Customer'
        when total_orders between 2 and 5 then 'Regular Customer'
        else 'VIP Customer'
    end as customer_segment,
    first_order_date,
    last_order_date,
    case 
        when last_order_date >= current_date - 30 then 'Active'
        when last_order_date >= current_date - 90 then 'At Risk'
        else 'Inactive'
    end as customer_status
from customer_orders
