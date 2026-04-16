-- Mart: daily revenue aggregation.
-- Similar to the DocumentDB aggregation pipeline, but enriched with USD conversion
-- and cross-referenced with CoinGecko crypto prices.

select
    toDate(created_at)              as revenue_date,
    currency,
    count(distinct order_id)        as order_count,
    sum(quantity)                   as items_sold,
    sum(line_total)                 as revenue_original,
    sum(line_total_usd)             as revenue_usd
from {{ ref('int_order_items_enriched') }}
where order_status = 'completed'
group by revenue_date, currency
order by revenue_date desc, currency
