select
    customer_id,
    customer_name,
    email,
    country,
    segment,
    created_at,
    _airbyte_extracted_at
from {{ source('raw', 'customers') }}
