select
    trim(cast(branch_id as string)) as branch_id,
    nullif(trim(cast(branch_name as string)), '') as branch_name,
    nullif(trim(cast(city as string)), '') as city,
    nullif(trim(cast(state as string)), '') as state,
    upper(trim(cast(branch_type as string))) as branch_type,
    safe_cast(opened_date as date) as opened_date,
    upper(trim(cast(region as string))) as region,
    safe_cast(updated_at as timestamp) as source_updated_at
from {{ source('banksphere_raw', 'branches') }}