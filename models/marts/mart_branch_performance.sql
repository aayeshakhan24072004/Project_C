with transaction_summary as (
    select
        branch_id,
        count(*) as transaction_count,
        countif(transaction_status = 'SUCCESS') as successful_transaction_count,
        sum(if(transaction_status = 'SUCCESS', amount, 0)) as successful_transaction_value
    from {{ ref('fact_transactions') }}
    group by branch_id
),
loan_summary as (
    select
        account.branch_id,
        countif(loan.loan_status = 'ACTIVE') as active_loan_count,
        sum(if(loan.loan_status = 'ACTIVE', loan.outstanding_amount, 0)) as active_loan_exposure
    from {{ ref('dim_loan') }} as loan
    inner join {{ ref('dim_account') }} as account using (account_id)
    group by account.branch_id
)

select
    branch.branch_id,
    branch.branch_name,
    branch.city,
    branch.state,
    branch.region,
    coalesce(transactions.transaction_count, 0) as transaction_count,
    coalesce(transactions.successful_transaction_count, 0) as successful_transaction_count,
    coalesce(transactions.successful_transaction_value, 0) as successful_transaction_value,
    coalesce(loans.active_loan_count, 0) as active_loan_count,
    coalesce(loans.active_loan_exposure, 0) as active_loan_exposure
from {{ ref('dim_branch') }} as branch
left join transaction_summary as transactions using (branch_id)
left join loan_summary as loans using (branch_id)