-- Intermediate: deduplicate orders (one row per order_id).
-- Keeps the latest Airbyte extraction for each order.

with ranked as (
    select
        *,
        row_number() over (
            partition by order_id
            order by _airbyte_extracted_at desc
        ) as _row_num
    from {{ ref('stg_orders') }}
)

select
    order_id,
    customer_id,
    order_status,
    currency,
    shipping_country,
    shipping_method,
    created_at,
    _airbyte_extracted_at
from ranked
where _row_num = 1
