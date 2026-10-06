select
    trim(cast(transaction_id as string)) as transaction_id,
    trim(cast(account_id as string)) as account_id,
    trim(cast(customer_id as string)) as customer_id,
    safe_cast(transaction_date as date) as transaction_date,
    upper(trim(cast(transaction_type as string))) as transaction_type,
    {{ standardize_transaction_classification('transaction_type') }} as transaction_classification,
    upper(trim(cast(channel as string))) as channel,
    safe_cast(amount as numeric) as amount,
    upper(trim(cast(currency as string))) as currency,
    upper(trim(cast(transaction_status as string))) as transaction_status,
    nullif(trim(cast(reference_number as string)), '') as reference_number,
    nullif(trim(cast(description as string)), '') as description,
    safe_cast(updated_at as timestamp) as source_updated_at
from {{ source('banksphere_raw', 'transactions') }}