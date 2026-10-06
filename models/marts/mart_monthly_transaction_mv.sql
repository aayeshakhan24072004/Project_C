{{ config(
    materialized='materialized_view',
    enable_refresh=true,
    refresh_interval_minutes=60
) }}

select
    date_trunc(transaction_date, month) as transaction_month,
    transaction_type,
    count(*) as successful_transaction_count,
    sum(amount) as successful_transaction_value
from {{ ref('fact_transactions') }}
where transaction_status = 'SUCCESS'
group by transaction_month, transaction_type