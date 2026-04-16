-- ClickHouse initialization: create the databases used by Airbyte and dbt.
-- Run this after ClickHouse starts:
--   clickhouse-client --password clickhouse < scripts/init-clickhouse.sql

CREATE DATABASE IF NOT EXISTS raw;
CREATE DATABASE IF NOT EXISTS staging;
CREATE DATABASE IF NOT EXISTS intermediate;
CREATE DATABASE IF NOT EXISTS analytics;
