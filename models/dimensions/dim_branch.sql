select
    branch_id,
    branch_name,
    city,
    state,
    branch_type,
    opened_date,
    region,
    source_updated_at
from {{ ref('stg_branches') }}