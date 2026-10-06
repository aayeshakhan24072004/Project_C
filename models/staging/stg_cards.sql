select
    trim(cast(card_id as string)) as card_id,
    trim(cast(account_id as string)) as account_id,
    trim(cast(customer_id as string)) as customer_id,
    upper(trim(cast(card_type as string))) as card_type,
    upper(trim(cast(card_status as string))) as card_status,
    upper(trim(cast(network as string))) as network,
    safe_cast(issue_date as date) as issue_date,
    safe_cast(expiry_date as date) as expiry_date,
    safe_cast(credit_limit as numeric) as credit_limit,
    safe_cast(updated_at as timestamp) as source_updated_at
from {{ source('banksphere_raw', 'cards') }}