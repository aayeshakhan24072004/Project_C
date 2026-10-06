{% macro log_run_event(event_name) %}
    {{ log('BankSphere dbt event: ' ~ event_name ~ ' | invocation_id=' ~ invocation_id, info=true) }}
    select current_timestamp() as event_logged_at
{% endmacro %}

{% macro log_model_hook(phase_name) %}
    select
        current_timestamp() as event_logged_at,
        '{{ this }}' as model_name,
        '{{ phase_name }}' as hook_phase,
        '{{ invocation_id }}' as invocation_id
{% endmacro %}