select
    customer_id,
    countif(transaction_status = 'SUCCESS') as successful_transaction_count,
    sum(if(transaction_status = 'SUCCESS', amount, 0)) as successful_transaction_value,
    max(if(transaction_status = 'SUCCESS', transaction_date, null)) as last_successful_transaction_date,
    countif(transaction_status = 'SUCCESS' and transaction_classification = 'DIGITAL_TRANSFER') as successful_digital_transaction_count,
    sum(if(transaction_status = 'SUCCESS' and transaction_classification = 'FEE', amount, 0)) as fee_amount,
    sum(if(transaction_status = 'SUCCESS' and transaction_classification = 'INTEREST', amount, 0)) as interest_amount
from {{ ref('int_account_transactions') }}
group by customer_id