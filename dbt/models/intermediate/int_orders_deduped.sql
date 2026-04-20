with ranked_orders as (
    select
        *,
        row_number() over (
            partition by order_id
            order by _airbyte_extracted_at desc, created_at desc
        ) as row_num
    from {{ ref('stg_orders') }}
)
select
    order_id,
    customer_id,
    order_status,
    currency,
    items,
    shipping,
    created_at,
    _airbyte_extracted_at
from ranked_orders
where row_num = 1
