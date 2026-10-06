-- Inefficient: full-table scan and no projection pruning.
select *
from {{ ref('fact_transactions') }};

-- Optimized: filter the partition column and project only required columns.
select transaction_date, account_id, transaction_type, amount
from {{ ref('fact_transactions') }}
where transaction_date >= date_sub(current_date(), interval 30 day)
  and transaction_date < current_date();