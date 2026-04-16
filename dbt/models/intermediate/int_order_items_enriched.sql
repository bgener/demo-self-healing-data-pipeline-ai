-- Intermediate: enrich order items with USD conversion.
-- For fiat currencies (USD, EUR, GBP), we use a static rate.
-- For crypto (BTC, ETH), we join with CoinGecko price snapshots.
-- This is the "data enrichment" step: cross-source joins.

with items as (
    select * from {{ ref('int_order_items_deduped') }}
),

-- Get the latest price per crypto currency
latest_prices as (
    select
        currency,
        price_usd,
        row_number() over (partition by currency order by price_at desc) as rn
    from {{ ref('stg_crypto_prices') }}
),

crypto_rates as (
    select currency, price_usd
    from latest_prices
    where rn = 1
),

enriched as (
    select
        i.order_id,
        i.customer_id,
        i.currency,
        i.order_status,
        i.created_at,
        i.sku,
        i.product_name,
        i.quantity,
        i.unit_price,
        i.line_total,

        -- Convert to USD based on currency type
        case
            when i.currency = 'USD' then i.line_total
            when i.currency = 'EUR' then i.line_total * 1.08
            when i.currency = 'GBP' then i.line_total * 1.27
            when i.currency in ('BTC', 'ETH') then i.line_total * coalesce(cr.price_usd, 0)
            else i.line_total
        end as line_total_usd,

        case
            when i.currency in ('BTC', 'ETH') then cr.price_usd
            else null
        end as crypto_price_usd

    from items i
    left join crypto_rates cr on i.currency = cr.currency
)

select * from enriched
