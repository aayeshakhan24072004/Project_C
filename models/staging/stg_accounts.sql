with accounts as (
    select
        trim(cast(account_id as string)) as account_id,
        trim(cast(customer_id as string)) as customer_id,
        trim(cast(branch_id as string)) as branch_id,
        upper(trim(cast(account_type as string))) as account_type,
        upper(trim(cast(account_status as string))) as account_status,
        upper(trim(cast(currency as string))) as currency,
        safe_cast(opening_date as date) as opening_date,
        safe_cast(credit_limit as numeric) as credit_limit,
        safe_cast(current_balance as numeric) as current_balance,
        safe_cast(updated_at as timestamp) as source_updated_at
    from {{ source('banksphere_raw', 'accounts') }}
)

select
    accounts.*,
    reference.product_group,
    reference.description as account_product_description
from accounts
left join {{ ref('banking_reference_codes') }} as reference
    on accounts.account_type = reference.product_code