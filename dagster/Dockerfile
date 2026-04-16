FROM python:3.12-slim

WORKDIR /opt/dagster

RUN pip install --no-cache-dir \
    dagster \
    dagster-webserver \
    dagster-airbyte \
    dagster-dbt \
    dbt-core \
    dbt-clickhouse

COPY . .

RUN mkdir -p /opt/dagster/dagster_home

ENV DAGSTER_HOME=/opt/dagster/dagster_home

EXPOSE 3000
