{{
  config(
    materialized='view'
  )
}}

-- Example staging model using sample data
-- Replace this with your actual source table once created

with sample_customers as (
    select 
        1 as customer_id,
        'John' as first_name,
        'Doe' as last_name,
        'john.doe@email.com' as email,
        '555-0101' as phone,
        '123 Main St' as address,
        'New York' as city,
        'NY' as state,
        '10001' as zip_code,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    union all
    select 
        2, 'Jane', 'Smith', 'jane.smith@email.com', '555-0102',
        '456 Oak Ave', 'Los Angeles', 'CA', '90210',
        current_timestamp(), current_timestamp()
    union all
    select 
        3, 'Bob', 'Johnson', 'bob.johnson@email.com', '555-0103',
        '789 Pine St', 'Chicago', 'IL', '60601',
        current_timestamp(), current_timestamp()
)

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
from sample_customers
