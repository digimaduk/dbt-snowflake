-- Example custom test
-- Tests that email addresses contain an @ symbol

select email
from {{ ref('stg_customers') }}
where email not like '%@%'
