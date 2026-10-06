{% snapshot account_snapshot %}
    {{ config(
        unique_key='account_id',
        strategy='check',
        check_cols=['account_status', 'current_balance', 'credit_limit', 'account_type'],
        hard_deletes='invalidate'
    ) }}

    select
        account_id,
        customer_id,
        branch_id,
        account_type,
        account_status,
        currency,
        opening_date,
        credit_limit,
        current_balance,
        source_updated_at
    from {{ ref('stg_accounts') }}
{% endsnapshot %}