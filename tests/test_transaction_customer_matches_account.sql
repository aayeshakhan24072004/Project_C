select
    transaction.transaction_id,
    transaction.customer_id as transaction_customer_id,
    account.customer_id as account_customer_id
from {{ ref('fact_transactions') }} as transaction
inner join {{ ref('dim_account') }} as account using (account_id)
where transaction.customer_id != account.customer_id