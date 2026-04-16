-- =============================================================================
-- Sample ClickHouse analytical queries on the transformed data.
-- Run these after the full ELT pipeline completes.
-- =============================================================================

-- Daily revenue by currency (USD-normalized)
SELECT
    revenue_date,
    currency,
    order_count,
    items_sold,
    round(revenue_original, 2) AS revenue_original,
    round(revenue_usd, 2) AS revenue_usd
FROM analytics.fct_daily_revenue
ORDER BY revenue_date DESC
LIMIT 20;

-- Top customers by lifetime value
SELECT
    customer_id,
    customer_name,
    country_code,
    segment,
    total_orders,
    round(lifetime_value_usd, 2) AS lifetime_value_usd
FROM analytics.dim_customers
ORDER BY lifetime_value_usd DESC
LIMIT 10;

-- Revenue breakdown: crypto vs fiat
SELECT
    if(currency IN ('BTC', 'ETH'), 'crypto', 'fiat') AS payment_type,
    count(DISTINCT order_id) AS orders,
    round(sum(line_total_usd), 2) AS total_revenue_usd,
    round(avg(line_total_usd), 2) AS avg_line_total_usd
FROM analytics.fct_order_lines
WHERE order_status = 'completed'
GROUP BY payment_type;

-- Best-selling products
SELECT
    sku,
    product_name,
    sum(quantity) AS total_units,
    round(sum(line_total_usd), 2) AS total_revenue_usd
FROM analytics.fct_order_lines
WHERE order_status = 'completed'
GROUP BY sku, product_name
ORDER BY total_revenue_usd DESC;

-- Revenue by shipping country
SELECT
    o.shipping_country,
    count(DISTINCT o.order_id) AS orders,
    round(sum(f.line_total_usd), 2) AS revenue_usd
FROM analytics.fct_order_lines f
JOIN intermediate.int_orders_deduped o ON f.order_id = o.order_id
GROUP BY o.shipping_country
ORDER BY revenue_usd DESC;
