with revenue_by_customer as (
    select
        customer_id,
        min(created_at) as first_order_at,
        max(created_at) as last_order_at,
        count(distinct order_id) as completed_orders,
        sum(line_total_usd) as lifetime_value_usd
    from {{ ref('fct_order_lines') }}
    where order_status = 'completed'
    group by 1
)
select
    customers.customer_id,
    customers.customer_name,
    customers.email,
    customers.country,
    customers.segment,
    customers.created_at as customer_created_at,
    revenue.first_order_at,
    revenue.last_order_at,
    coalesce(revenue.completed_orders, 0) as completed_orders,
    coalesce(revenue.lifetime_value_usd, 0)::numeric(18, 2) as lifetime_value_usd
from {{ ref('stg_customers') }} as customers
left join revenue_by_customer as revenue
    on customers.customer_id = revenue.customer_id
