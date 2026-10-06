with transaction_income as (
    select
        customer_id,
        sum(if(transaction_status = 'SUCCESS' and transaction_classification = 'FEE', amount, 0)) as transaction_fee_income,
        sum(if(transaction_status = 'SUCCESS' and transaction_classification = 'INTEREST', amount, 0)) as transaction_interest_income
    from {{ ref('fact_transactions') }}
    group by customer_id
),
repayment_income as (
    select
        loan.customer_id,
        sum(if(payment.payment_status = 'SUCCESS', payment.interest_amount, 0)) as loan_payment_interest_income
    from {{ ref('fact_loan_payments') }} as payment
    inner join {{ ref('dim_loan') }} as loan using (loan_id)
    group by loan.customer_id
)

select
    customer.customer_id,
    customer.customer_segment,
    coalesce(transaction_income.transaction_fee_income, 0) as transaction_fee_income,
    coalesce(transaction_income.transaction_interest_income, 0) as transaction_interest_income,
    coalesce(repayment_income.loan_payment_interest_income, 0) as loan_payment_interest_income,
    coalesce(transaction_income.transaction_fee_income, 0)
        + coalesce(transaction_income.transaction_interest_income, 0)
        + coalesce(repayment_income.loan_payment_interest_income, 0) as observed_gross_income,
    coalesce(activity.successful_transaction_value, 0) as successful_transaction_value,
    coalesce(activity.successful_transaction_value, 0) >= {{ var('high_value_transaction_threshold') }} as is_high_value_customer
from {{ ref('dim_customer') }} as customer
left join transaction_income using (customer_id)
left join repayment_income using (customer_id)
left join {{ ref('int_customer_activity') }} as activity using (customer_id)