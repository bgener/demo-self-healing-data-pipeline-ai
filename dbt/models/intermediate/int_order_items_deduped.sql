-- Intermediate: deduplicate order items.
-- Airbyte in append mode can produce duplicates when re-syncing.
-- We keep only the latest extraction per (order_id, sku) pair.

with ranked as (
    select
        *,
        row_number() over (
            partition by order_id, sku
            order by _airbyte_extracted_at desc
        ) as _row_num
    from {{ ref('stg_order_items') }}
)

select
    order_id,
    customer_id,
    currency,
    order_status,
    created_at,
    sku,
    product_name,
    quantity,
    unit_price,
    line_total,
    _airbyte_extracted_at
from ranked
where _row_num = 1
