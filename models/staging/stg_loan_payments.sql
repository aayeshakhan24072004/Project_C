select
    trim(cast(payment_id as string)) as payment_id,
    trim(cast(loan_id as string)) as loan_id,
    safe_cast(payment_date as date) as payment_date,
    safe_cast(payment_amount as numeric) as payment_amount,
    safe_cast(principal_amount as numeric) as principal_amount,
    safe_cast(interest_amount as numeric) as interest_amount,
    upper(trim(cast(payment_status as string))) as payment_status,
    upper(trim(cast(payment_channel as string))) as payment_channel,
    safe_cast(updated_at as timestamp) as source_updated_at
from {{ source('banksphere_raw', 'loan_payments') }}