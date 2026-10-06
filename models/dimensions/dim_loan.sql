select
    loan_id,
    customer_id,
    account_id,
    loan_type,
    loan_status,
    application_date,
    sanctioned_amount,
    interest_rate,
    tenure_months,
    outstanding_amount,
    source_updated_at
from {{ ref('stg_loans') }}