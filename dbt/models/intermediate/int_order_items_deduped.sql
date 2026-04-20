with ranked_items as (
    select
        *,
        row_number() over (
            partition by order_id, sku
            order by created_at desc
        ) as row_num
    from {{ ref('stg_order_items') }}
)
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
    line_total
from ranked_items
where row_num = 1
