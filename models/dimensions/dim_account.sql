select
    account_id,
    customer_id,
    branch_id,
    account_type,
    account_status,
    currency,
    opening_date,
    credit_limit,
    current_balance,
    product_group,
    account_product_description,
    source_updated_at
from {{ ref('stg_accounts') }}