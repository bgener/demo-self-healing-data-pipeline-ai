select
    order_id,
    sku,
    count(*) as duplicate_count
from {{ ref('fct_order_lines') }}
group by 1, 2
having count(*) > 1
