{% macro standardize_transaction_classification(transaction_type) -%}
    case
        when upper(trim(cast({{ transaction_type }} as string))) in ('IMPS', 'NEFT', 'UPI', 'TRANSFER') then 'DIGITAL_TRANSFER'
        when upper(trim(cast({{ transaction_type }} as string))) in ('ATM_WITHDRAWAL', 'WITHDRAWAL') then 'CASH_WITHDRAWAL'
        when upper(trim(cast({{ transaction_type }} as string))) = 'DEPOSIT' then 'DEPOSIT'
        when upper(trim(cast({{ transaction_type }} as string))) = 'CARD_PAYMENT' then 'CARD_PAYMENT'
        when upper(trim(cast({{ transaction_type }} as string))) = 'INTEREST' then 'INTEREST'
        when upper(trim(cast({{ transaction_type }} as string))) = 'FEE' then 'FEE'
        else 'OTHER'
    end
{%- endmacro %}