{{ config(materialized='ephemeral') }}

select
    transactions.transaction_id,
    transactions.account_id,
    transactions.customer_id,
    accounts.branch_id,
    transactions.transaction_date,
    transactions.transaction_type,
    transactions.transaction_classification,
    transactions.channel,
    transactions.amount,
    transactions.currency,
    transactions.transaction_status,
    transactions.reference_number,
    transactions.source_updated_at,
    accounts.account_type,
    accounts.account_status
from {{ ref('stg_transactions') }} as transactions
inner join {{ ref('stg_accounts') }} as accounts
    on transactions.account_id = accounts.account_id