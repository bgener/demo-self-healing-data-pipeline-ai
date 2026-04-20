from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from bson.decimal128 import Decimal128
import psycopg2
from psycopg2.extras import Json
from pymongo import MongoClient


def normalize_datetime(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc)


def normalize_bson_value(value: Any) -> Any:
    if isinstance(value, Decimal128):
        return float(value.to_decimal())
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, datetime):
        normalized = value if value.tzinfo else value.replace(tzinfo=timezone.utc)
        return normalized.isoformat()
    if isinstance(value, list):
        return [normalize_bson_value(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize_bson_value(item) for key, item in value.items()}
    return value


def main() -> None:
    mongo = MongoClient(os.getenv("MONGO_CONNECTION_STRING", "mongodb://mongo:27017"))
    database = mongo[os.getenv("MONGO_DATABASE", "ecommerce")]
    extracted_at = datetime.now(timezone.utc)

    connection = psycopg2.connect(
        host=os.getenv("PGHOST", "timescaledb"),
        port=os.getenv("PGPORT", "5432"),
        user=os.getenv("PGUSER", "pipeline"),
        password=os.getenv("PGPASSWORD", "pipeline"),
        dbname=os.getenv("PGDATABASE", "warehouse"),
    )

    with connection, connection.cursor() as cursor:
        cursor.execute("truncate table raw.orders;")
        cursor.execute("truncate table raw.customers;")

        customers = list(database.customers.find({}, {"_id": 0}))
        for customer in customers:
            cursor.execute(
                """
                insert into raw.customers (
                    _airbyte_raw_id,
                    _airbyte_extracted_at,
                    customer_id,
                    customer_name,
                    email,
                    country,
                    segment,
                    created_at
                ) values (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    f"customer::{customer['customerId']}",
                    extracted_at,
                    customer["customerId"],
                    customer["name"],
                    customer["email"],
                    customer["country"],
                    customer["segment"],
                    normalize_datetime(customer.get("createdAt")),
                ),
            )

        orders = list(database.orders.find({}, {"_id": 0}))
        for order in orders:
            cursor.execute(
                """
                insert into raw.orders (
                    _airbyte_raw_id,
                    _airbyte_extracted_at,
                    order_id,
                    customer_id,
                    order_status,
                    currency,
                    items,
                    shipping,
                    created_at
                ) values (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    f"order::{order['orderId']}",
                    extracted_at,
                    order["orderId"],
                    order["customerId"],
                    order["status"],
                    order["currency"],
                    Json(normalize_bson_value(order.get("items", [])), dumps=json.dumps),
                    Json(normalize_bson_value(order.get("shipping", {})), dumps=json.dumps),
                    normalize_datetime(order.get("createdAt")),
                ),
            )


if __name__ == "__main__":
    main()
