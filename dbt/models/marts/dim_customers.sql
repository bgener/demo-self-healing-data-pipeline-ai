-- Mart: customer dimension with lifetime metrics.
-- Joins deduplicated customers with aggregated order data.

with customers as (
    select
        customer_id,
        customer_name,
        email,
        country_code,
        segment,
        created_at as customer_since,
        row_number() over (partition by customer_id order by _airbyte_extracted_at desc) as rn
    from {{ ref('stg_customers') }}
),

deduped_customers as (
    select * from customers where rn = 1
),

order_metrics as (
    select
        customer_id,
        count(distinct order_id)    as total_orders,
        sum(line_total_usd)         as lifetime_value_usd,
        min(created_at)             as first_order_at,
        max(created_at)             as last_order_at
    from {{ ref('int_order_items_enriched') }}
    where order_status = 'completed'
    group by customer_id
)

select
    c.customer_id,
    c.customer_name,
    c.email,
    c.country_code,
    c.segment,
    c.customer_since,
    coalesce(m.total_orders, 0)         as total_orders,
    coalesce(m.lifetime_value_usd, 0)   as lifetime_value_usd,
    m.first_order_at,
    m.last_order_at
from deduped_customers c
left join order_metrics m on c.customer_id = m.customer_id
