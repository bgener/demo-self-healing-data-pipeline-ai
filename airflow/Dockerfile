FROM apache/airflow:2.10.5-python3.12

COPY requirements.txt /tmp/requirements.txt

RUN pip install --no-cache-dir -r /tmp/requirements.txt

ENV PATH="/home/airflow/.local/bin:${PATH}"
