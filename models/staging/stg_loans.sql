select
    trim(cast(loan_id as string)) as loan_id,
    trim(cast(customer_id as string)) as customer_id,
    trim(cast(account_id as string)) as account_id,
    upper(trim(cast(loan_type as string))) as loan_type,
    upper(trim(cast(loan_status as string))) as loan_status,
    safe_cast(application_date as date) as application_date,
    safe_cast(sanctioned_amount as numeric) as sanctioned_amount,
    safe_cast(interest_rate as numeric) as interest_rate,
    safe_cast(tenure_months as int64) as tenure_months,
    safe_cast(outstanding_amount as numeric) as outstanding_amount,
    safe_cast(updated_at as timestamp) as source_updated_at
from {{ source('banksphere_raw', 'loans') }}