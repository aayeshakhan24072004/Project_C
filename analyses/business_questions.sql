-- Monthly successful transaction value.
select
    date_trunc(transaction_date, month) as transaction_month,
    sum(if(transaction_status = 'SUCCESS', amount, 0)) as successful_transaction_value
from {{ ref('fact_transactions') }}
group by transaction_month
order by transaction_month;

-- Top 20 customers by successful transaction value.
select customer_id, sum(amount) as successful_transaction_value
from {{ ref('fact_transactions') }}
where transaction_status = 'SUCCESS'
group by customer_id
order by successful_transaction_value desc
limit 20;

-- Customers without a successful transaction in the past 90 days.
select customer_id, has_no_successful_transaction_90d
from {{ ref('mart_customer_360') }}
where has_no_successful_transaction_90d;

-- Monthly growth in successful transaction value.
with monthly as (
    select
        date_trunc(transaction_date, month) as transaction_month,
        sum(if(transaction_status = 'SUCCESS', amount, 0)) as successful_value
    from {{ ref('fact_transactions') }}
    group by transaction_month
)
select
    transaction_month,
    successful_value,
    safe_divide(successful_value - lag(successful_value) over (order by transaction_month),
        lag(successful_value) over (order by transaction_month)) as month_over_month_growth
from monthly
order by transaction_month;

-- Transaction mix by channel.
select
    channel,
    count(*) as transaction_count,
    sum(if(transaction_status = 'SUCCESS', amount, 0)) as successful_transaction_value
from {{ ref('fact_transactions') }}
group by channel
order by successful_transaction_value desc;

-- ATM cash withdrawals versus digital transfers by day.
select
    transaction_date,
    sum(successful_cash_withdrawal_value) as cash_withdrawal_value,
    sum(successful_digital_transfer_value) as digital_transfer_value
from {{ ref('mart_daily_transactions') }}
group by transaction_date
order by transaction_date;

-- Active versus dormant account distribution.
select account_status, count(*) as account_count
from {{ ref('dim_account') }}
group by account_status
order by account_count desc;

-- Top branches by active loan exposure.
select branch_id, branch_name, active_loan_count, active_loan_exposure
from {{ ref('mart_branch_performance') }}
order by active_loan_exposure desc
limit 20;

-- Loan repayment success and late-payment rates.
select
    loan_type,
    sum(payment_count) as payment_count,
    {{ safe_ratio('sum(successful_payment_count)', 'sum(payment_count)') }} as successful_payment_rate,
    {{ safe_ratio('sum(late_payment_count)', 'sum(payment_count)') }} as late_payment_rate
from {{ ref('int_loan_summary') }}
group by loan_type
order by late_payment_rate desc;

-- Configurable high-value customer list; threshold defaults to 100,000.
select customer_id, customer_name, customer_segment, successful_transaction_value
from {{ ref('mart_customer_360') }}
where is_high_value_customer
order by successful_transaction_value desc;