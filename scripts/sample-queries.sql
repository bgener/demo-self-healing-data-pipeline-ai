select count(*) as order_lines
from marts.fct_order_lines;

select
    revenue_date,
    currency,
    revenue_usd
from marts.fct_daily_revenue
order by revenue_date desc, revenue_usd desc
limit 20;

select
    customer_id,
    customer_name,
    lifetime_value_usd
from marts.dim_customers
order by lifetime_value_usd desc
limit 10;
