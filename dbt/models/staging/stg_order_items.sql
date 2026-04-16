-- Staging: explode the nested items[] array into one row per line item.
-- This is the core "flatten" step for document-to-relational transformation.

with source as (
    select * from {{ source('airbyte_raw', 'orders') }}
),

-- Use ClickHouse's JSONExtract + arrayJoin to flatten the items array
flattened as (
    select
        orderId                                                     as order_id,
        customerId                                                  as customer_id,
        upper(currency)                                             as currency,
        status                                                      as order_status,
        toDateTime(createdAt)                                       as created_at,
        JSONExtractString(item, 'sku')                              as sku,
        JSONExtractString(item, 'productName')                      as product_name,
        JSONExtractInt(item, 'qty')                                 as quantity,
        JSONExtractFloat(item, 'unitPrice')                         as unit_price,
        _airbyte_raw_id,
        _airbyte_extracted_at
    from source
    array join JSONExtractArrayRaw(items) as item
)

select
    *,
    quantity * unit_price as line_total
from flattened
