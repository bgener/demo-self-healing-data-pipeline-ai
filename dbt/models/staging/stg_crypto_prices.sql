-- Staging: CoinGecko price snapshots.
-- Maps coin symbols to the currency codes used in orders (BTC, ETH).

with source as (
    select * from {{ source('airbyte_raw', 'coingecko_prices') }}
),

cleaned as (
    select
        id                                      as coin_id,
        upper(symbol)                           as currency,
        current_price                           as price_usd,
        toDateTime(last_updated)                as price_at,
        _airbyte_raw_id,
        _airbyte_extracted_at
    from source
)

select * from cleaned
