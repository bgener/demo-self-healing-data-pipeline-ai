-- Data quality test: all completed order line items should have positive USD revenue.

select
    order_id,
    sku,
    line_total_usd
from {{ ref('fct_order_lines') }}
where order_status = 'completed'
  and line_total_usd <= 0
