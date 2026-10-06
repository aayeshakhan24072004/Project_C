select
    payment_id,
    loan_id,
    payment_date,
    payment_amount,
    principal_amount,
    interest_amount,
    payment_status,
    payment_channel,
    source_updated_at
from {{ ref('stg_loan_payments') }}