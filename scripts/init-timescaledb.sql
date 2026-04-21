create extension if not exists timescaledb;

-- Pipeline role (non-superuser). Terraform manages its schema grants.
do $$
begin
  if not exists (select from pg_roles where rolname = 'pipeline') then
    create role pipeline with login password 'pipeline';
  end if;
end
$$;

create schema if not exists raw;
create schema if not exists staging;
create schema if not exists intermediate;
create schema if not exists marts;

create table if not exists raw.orders (
    _airbyte_raw_id text not null,
    _airbyte_extracted_at timestamptz not null,
    order_id text not null,
    customer_id text not null,
    order_status text not null,
    currency text not null,
    items jsonb not null,
    shipping jsonb not null,
    created_at timestamptz not null
);

create table if not exists raw.customers (
    _airbyte_raw_id text not null,
    _airbyte_extracted_at timestamptz not null,
    customer_id text not null,
    customer_name text not null,
    email text not null,
    country text not null,
    segment text not null,
    created_at timestamptz not null
);

create index if not exists ix_raw_orders_created_at on raw.orders (created_at desc);
create index if not exists ix_raw_orders_customer_id on raw.orders (customer_id);
create index if not exists ix_raw_customers_customer_id on raw.customers (customer_id);
create unique index if not exists ux_raw_customers_airbyte_raw_id on raw.customers (_airbyte_raw_id);

select create_hypertable('raw.orders', 'created_at', if_not_exists => true);
