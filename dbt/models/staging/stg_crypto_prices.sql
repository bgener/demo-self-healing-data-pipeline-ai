select
    'BTC'::text as currency,
    68000.00::numeric(18, 2) as usd_rate
union all
select
    'ETH'::text as currency,
    3200.00::numeric(18, 2) as usd_rate
union all
select
    'EUR'::text as currency,
    1.08::numeric(18, 2) as usd_rate
union all
select
    'GBP'::text as currency,
    1.27::numeric(18, 2) as usd_rate
union all
select
    'USD'::text as currency,
    1.00::numeric(18, 2) as usd_rate
