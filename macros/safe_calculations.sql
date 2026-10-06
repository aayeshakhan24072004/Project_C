{% macro safe_ratio(numerator, denominator) -%}
    safe_divide({{ numerator }}, {{ denominator }})
{%- endmacro %}