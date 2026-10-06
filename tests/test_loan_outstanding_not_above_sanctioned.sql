select loan_id, outstanding_amount, sanctioned_amount
from {{ ref('dim_loan') }}
where outstanding_amount > sanctioned_amount