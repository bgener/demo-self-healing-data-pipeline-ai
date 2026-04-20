select
    order_id,
    customer_id,
    order_status,
    currency,
    created_at,
    sku,
    product_name,
    quantity,
    unit_price,
    line_total,
    usd_rate,
    line_total_usd
from {{ ref('int_order_items_enriched') }}
