select
    loan_type,
    loan_status,
    count(*) as loan_count,
    sum(sanctioned_amount) as total_sanctioned_amount,
    sum(outstanding_amount) as total_outstanding_amount,
    sum(if(loan_status = 'ACTIVE', outstanding_amount, 0)) as active_loan_exposure,
    sum(payment_count) as payment_count,
    sum(successful_payment_count) as successful_payment_count,
    sum(late_payment_count) as late_payment_count,
    sum(failed_payment_count) as failed_payment_count,
    {{ safe_ratio('sum(late_payment_count)', 'sum(payment_count)') }} as late_payment_rate
from {{ ref('int_loan_summary') }}
group by loan_type, loan_status