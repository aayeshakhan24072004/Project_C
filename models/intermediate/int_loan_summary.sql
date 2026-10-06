with payment_summary as (
    select
        loan_id,
        count(*) as payment_count,
        countif(payment_status = 'SUCCESS') as successful_payment_count,
        countif(payment_status = 'LATE') as late_payment_count,
        countif(payment_status = 'FAILED') as failed_payment_count,
        sum(if(payment_status = 'SUCCESS', payment_amount, 0)) as successful_payment_amount
    from {{ ref('stg_loan_payments') }}
    group by loan_id
)

select
    loans.loan_id,
    loans.customer_id,
    loans.account_id,
    loans.loan_type,
    loans.loan_status,
    loans.application_date,
    loans.sanctioned_amount,
    loans.interest_rate,
    loans.tenure_months,
    loans.outstanding_amount,
    loans.source_updated_at,
    coalesce(payment_summary.payment_count, 0) as payment_count,
    coalesce(payment_summary.successful_payment_count, 0) as successful_payment_count,
    coalesce(payment_summary.late_payment_count, 0) as late_payment_count,
    coalesce(payment_summary.failed_payment_count, 0) as failed_payment_count,
    coalesce(payment_summary.successful_payment_amount, 0) as successful_payment_amount,
    {{ safe_ratio('payment_summary.late_payment_count', 'payment_summary.payment_count') }} as late_payment_rate
from {{ ref('stg_loans') }} as loans
left join payment_summary using (loan_id)