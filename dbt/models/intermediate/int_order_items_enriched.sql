select
    items.order_id,
    items.customer_id,
    items.order_status,
    items.currency,
    items.created_at,
    items.sku,
    items.product_name,
    items.quantity,
    items.unit_price,
    items.line_total,
    rates.usd_rate,
    (items.line_total * rates.usd_rate)::numeric(18, 2) as line_total_usd
from {{ ref('int_order_items_deduped') }} as items
inner join {{ ref('stg_crypto_prices') }} as rates
    on items.currency = rates.currency
