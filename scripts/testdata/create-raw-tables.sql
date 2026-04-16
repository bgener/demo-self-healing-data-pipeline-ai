-- Raw tables matching Airbyte's output schema in ClickHouse.
-- In production, Airbyte creates these automatically. In CI, we create them
-- manually and load synthetic data to test the dbt transform layer.

CREATE TABLE IF NOT EXISTS raw.orders
(
    _airbyte_raw_id       String,
    _airbyte_extracted_at DateTime64(3) DEFAULT now(),
    orderId               String,
    customerId            String,
    status                String,
    currency              String,
    items                 String,   -- JSON array
    shipping              String,   -- JSON object
    createdAt             DateTime64(3)
)
ENGINE = MergeTree()
ORDER BY (orderId, _airbyte_extracted_at);

CREATE TABLE IF NOT EXISTS raw.customers
(
    _airbyte_raw_id       String,
    _airbyte_extracted_at DateTime64(3) DEFAULT now(),
    customerId            String,
    name                  String,
    email                 String,
    country               String,
    segment               String,
    createdAt             DateTime64(3)
)
ENGINE = MergeTree()
ORDER BY (customerId, _airbyte_extracted_at);

CREATE TABLE IF NOT EXISTS raw.coingecko_prices
(
    _airbyte_raw_id       String,
    _airbyte_extracted_at DateTime64(3) DEFAULT now(),
    id                    String,
    symbol                String,
    current_price         Float64,
    last_updated          DateTime64(3)
)
ENGINE = MergeTree()
ORDER BY (symbol, _airbyte_extracted_at);
