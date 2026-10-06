{% macro banksphere_run_operation_demo() %}
    {{ log('BankSphere run-operation executed for target ' ~ target.name ~ ' in dataset ' ~ target.schema, info=true) }}
{% endmacro %}