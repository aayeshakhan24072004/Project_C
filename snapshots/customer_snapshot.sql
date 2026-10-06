{% snapshot customer_snapshot %}
    {{ config(
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='source_updated_at',
        hard_deletes='invalidate'
    ) }}

    select
        customer_id,
        customer_name,
        email,
        phone,
        city,
        state,
        customer_segment,
        date_of_birth,
        signup_date,
        kyc_status,
        source_updated_at
    from {{ ref('stg_customers') }}
{% endsnapshot %}