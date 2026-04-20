select
    order_id,
    customer_id,
    order_status,
    currency,
    items,
    shipping,
    created_at,
    _airbyte_extracted_at
from {{ source('raw', 'orders') }}
