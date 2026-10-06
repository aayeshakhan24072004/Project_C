with dates as (
    {{ dbt_utils.date_spine(
        datepart='day',
        start_date="date '" ~ var('analysis_start_date') ~ "'",
        end_date='date_add(current_date(), interval 1 day)'
    ) }}
)

select
    date_day,
    cast(format_date('%Y%m%d', date_day) as int64) as date_id,
    extract(year from date_day) as year_number,
    extract(quarter from date_day) as quarter_number,
    extract(month from date_day) as month_number,
    format_date('%B', date_day) as month_name,
    format_date('%Y-%m', date_day) as year_month,
    extract(day from date_day) as day_of_month,
    extract(dayofweek from date_day) as day_of_week_number,
    format_date('%A', date_day) as day_name,
    extract(dayofweek from date_day) in (1, 7) as is_weekend
from dates