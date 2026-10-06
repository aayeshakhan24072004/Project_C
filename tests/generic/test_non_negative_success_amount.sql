{% test non_negative_success_amount(model, column_name, status_column) %}

select *
from {{ model }}
where {{ status_column }} = 'SUCCESS'
  and {{ column_name }} < 0

{% endtest %}