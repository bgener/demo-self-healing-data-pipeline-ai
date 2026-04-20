select
    date_trunc('day', created_at) as revenue_date,
    currency,
    count(distinct order_id) as order_count,
    sum(quantity) as units_sold,
    sum(line_total) as revenue_native,
    sum(line_total_usd) as revenue_usd
from {{ ref('fct_order_lines') }}
where order_status = 'completed'
group by 1, 2
