select
    card_id,
    account_id,
    customer_id,
    card_type,
    card_status,
    network,
    issue_date,
    expiry_date,
    credit_limit,
    source_updated_at
from {{ ref('stg_cards') }}