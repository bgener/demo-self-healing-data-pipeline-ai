-- Data quality test: verify deduplication worked.
-- This should return zero rows if int_order_items_deduped is correct.

select
    order_id,
    sku,
    count(*) as duplicate_count
from {{ ref('int_order_items_deduped') }}
group by order_id, sku
having count(*) > 1
