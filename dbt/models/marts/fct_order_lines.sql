-- Mart: fact table for order line items.
-- Fully deduplicated, enriched with USD amounts, ready for analytics.

select
    order_id,
    customer_id,
    sku,
    product_name,
    quantity,
    unit_price,
    currency,
    line_total,
    line_total_usd,
    crypto_price_usd,
    order_status,
    created_at,
    toDate(created_at) as order_date
from {{ ref('int_order_items_enriched') }}
