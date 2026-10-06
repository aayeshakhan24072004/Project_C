select
    trim(cast(customer_id as string)) as customer_id,
    nullif(trim(cast(customer_name as string)), '') as customer_name,
    nullif(lower(trim(cast(email as string))), '') as email,
    nullif(trim(cast(phone as string)), '') as phone,
    nullif(trim(cast(city as string)), '') as city,
    nullif(trim(cast(state as string)), '') as state,
    upper(trim(cast(customer_segment as string))) as customer_segment,
    safe_cast(date_of_birth as date) as date_of_birth,
    safe_cast(signup_date as date) as signup_date,
    upper(trim(cast(kyc_status as string))) as kyc_status,
    safe_cast(updated_at as timestamp) as source_updated_at
from {{ source('banksphere_raw', 'customers') }}