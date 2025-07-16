FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common curl git && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.8 python3.8-venv python3.8-dev \
        gcc build-essential default-libmysqlclient-dev \
        pkg-config netcat-openbsd && \
    apt-get clean

WORKDIR /app

COPY . /app

RUN python3.8 -m venv venv && \
    ./venv/bin/pip install --upgrade pip && \
    ./venv/bin/pip install -r requirements.txt && \
    ./venv/bin/pip install gunicorn mysqlclient

ENV DB_NAME=chatappdb \
    DB_USER=arpit \
    DB_PASSWORD=Jodhpur@21 \
    DB_HOST=mysql-container \
    DB_PORT=3306

CMD bash -c '  echo "Waiting for MySQL at $DB_HOST:$DB_PORT..." && \
  until nc -z "$DB_HOST" "$DB_PORT"; do sleep 2; echo "Waiting..."; done && \
  echo "DB is ready!" && \
  /app/venv/bin/python /app/fundoo/manage.py migrate && \
  exec /app/venv/bin/gunicorn --chdir /app/fundoo --bind 0.0.0.0:8000 fundoo.wsgi:application'
