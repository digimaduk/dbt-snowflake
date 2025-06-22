-- Custom test to ensure kyc_profile data is fresh (updated within last 15 minutes)
-- This test helps monitor if the 10-minute sync job is working properly

select
    count(*) as stale_records
from {{ ref('kyc_profile') }}
where updated_date < current_timestamp() - interval '15 minutes'

-- If any records are older than 15 minutes, this indicates
-- the sync process may have issues
