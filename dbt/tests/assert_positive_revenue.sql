select
    *
from {{ ref('fct_order_lines') }}
where order_status = 'completed'
  and line_total_usd <= 0
