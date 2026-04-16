-- Staging: flatten nested order documents from DocumentDB.
-- Airbyte loads the full JSON document; we extract top-level fields
-- and parse the nested shipping object.

with source as (
    select * from {{ source('airbyte_raw', 'orders') }}
),

cleaned as (
    select
        orderId                                         as order_id,
        customerId                                      as customer_id,
        status                                          as order_status,
        upper(currency)                                 as currency,
        items                                           as items_raw,
        JSONExtractString(shipping, 'country')          as shipping_country,
        JSONExtractString(shipping, 'method')            as shipping_method,
        toDateTime(createdAt)                           as created_at,
        _airbyte_raw_id,
        _airbyte_extracted_at
    from source
)

select * from cleaned
