select
    transaction_date,
    channel,
    transaction_type,
    count(*) as transaction_count,
    countif(transaction_status = 'SUCCESS') as successful_transaction_count,
    sum(if(transaction_status = 'SUCCESS', amount, 0)) as successful_transaction_value,
    countif(transaction_status = 'FAILED') as failed_transaction_count,
    countif(transaction_status = 'REVERSED') as reversed_transaction_count,
    sum(if(transaction_status = 'SUCCESS' and transaction_classification = 'CASH_WITHDRAWAL', amount, 0)) as successful_cash_withdrawal_value,
    sum(if(transaction_status = 'SUCCESS' and transaction_classification = 'DIGITAL_TRANSFER', amount, 0)) as successful_digital_transfer_value
from {{ ref('fact_transactions') }}
group by transaction_date, channel, transaction_type