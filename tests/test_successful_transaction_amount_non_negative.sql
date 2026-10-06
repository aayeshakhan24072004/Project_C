select transaction_id, amount
from {{ ref('fact_transactions') }}
where transaction_status = 'SUCCESS'
  and amount < 0