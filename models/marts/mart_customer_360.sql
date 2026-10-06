with account_summary as (
    select
        customer_id,
        count(*) as account_count,
        countif(account_status = 'ACTIVE') as active_account_count,
        sum(current_balance) as total_current_balance
    from {{ ref('dim_account') }}
    group by customer_id
),
card_summary as (
    select
        customer_id,
        count(*) as card_count,
        countif(card_status = 'ACTIVE') as active_card_count
    from {{ ref('dim_card') }}
    group by customer_id
),
loan_summary as (
    select
        customer_id,
        count(*) as loan_count,
        countif(loan_status = 'ACTIVE') as active_loan_count,
        sum(if(loan_status = 'ACTIVE', outstanding_amount, 0)) as active_loan_exposure,
        sum(outstanding_amount) as total_loan_outstanding
    from {{ ref('dim_loan') }}
    group by customer_id
)

select
    customer.customer_id,
    customer.customer_name,
    customer.email,
    customer.city,
    customer.state,
    customer.customer_segment,
    customer.kyc_status,
    coalesce(accounts.account_count, 0) as account_count,
    coalesce(accounts.active_account_count, 0) as active_account_count,
    coalesce(accounts.total_current_balance, 0) as total_current_balance,
    coalesce(cards.card_count, 0) as card_count,
    coalesce(cards.active_card_count, 0) as active_card_count,
    coalesce(activity.successful_transaction_count, 0) as successful_transaction_count,
    coalesce(activity.successful_transaction_value, 0) as successful_transaction_value,
    activity.last_successful_transaction_date,
    coalesce(activity.successful_transaction_value, 0) >= {{ var('high_value_transaction_threshold') }} as is_high_value_customer,
    activity.last_successful_transaction_date is null
        or activity.last_successful_transaction_date < date_sub(current_date(), interval 90 day) as has_no_successful_transaction_90d,
    coalesce(loans.loan_count, 0) as loan_count,
    coalesce(loans.active_loan_count, 0) as active_loan_count,
    coalesce(loans.active_loan_exposure, 0) as active_loan_exposure,
    coalesce(loans.total_loan_outstanding, 0) as total_loan_outstanding
from {{ ref('dim_customer') }} as customer
left join account_summary as accounts using (customer_id)
left join card_summary as cards using (customer_id)
left join {{ ref('int_customer_activity') }} as activity using (customer_id)
left join loan_summary as loans using (customer_id)