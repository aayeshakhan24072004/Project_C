select
    customer_id,
    customer_name,
    email,
    phone,
    city,
    state,
    customer_segment,
    date_of_birth,
    signup_date,
    kyc_status,
    source_updated_at
from {{ ref('stg_customers') }}