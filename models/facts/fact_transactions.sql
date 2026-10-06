{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='transaction_id',
    on_schema_change='append_new_columns',
    partition_by={'field': 'transaction_date', 'data_type': 'date'},
    cluster_by=['account_id', 'customer_id', 'transaction_type'],
    pre_hook="{{ log_model_hook('pre') }}",
    post_hook="{{ log_model_hook('post') }}"
) }}

select
    transaction_id,
    account_id,
    customer_id,
    branch_id,
    transaction_date,
    transaction_type,
    transaction_classification,
    channel,
    amount,
    currency,
    transaction_status,
    reference_number,
    source_updated_at
from {{ ref('int_account_transactions') }}
{% if is_incremental() %}
where source_updated_at >= timestamp_sub(
    coalesce((select max(source_updated_at) from {{ this }}), timestamp '1900-01-01 00:00:00+00'),
    interval {{ var('transaction_incremental_lookback_days', 3) }} day
)
{% endif %}