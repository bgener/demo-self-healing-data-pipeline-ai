select
    orders.order_id,
    orders.customer_id,
    orders.order_status,
    orders.currency,
    orders.created_at,
    item.value ->> 'sku' as sku,
    item.value ->> 'productName' as product_name,
    (item.value ->> 'qty')::integer as quantity,
    (item.value ->> 'unitPrice')::numeric(18, 2) as unit_price,
    ((item.value ->> 'qty')::integer * (item.value ->> 'unitPrice')::numeric(18, 2))::numeric(18, 2) as line_total
from {{ ref('stg_orders') }} as orders
cross join lateral jsonb_array_elements(orders.items) as item(value)
