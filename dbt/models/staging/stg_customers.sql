-- Staging: clean customer documents from DocumentDB.

with source as (
    select * from {{ source('airbyte_raw', 'customers') }}
),

cleaned as (
    select
        customerId              as customer_id,
        name                    as customer_name,
        email,
        upper(country)          as country_code,
        lower(segment)          as segment,
        toDateTime(createdAt)   as created_at,
        _airbyte_raw_id,
        _airbyte_extracted_at
    from source
)

select * from cleaned
