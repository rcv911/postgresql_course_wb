#!/bin/bash
set -e

# Скачиваем файл
wget https://storage.googleapis.com/thaibus/thai_medium.tar.gz -O /tmp/thai_medium.tar.gz

# Распаковываем файл
tar -xvzf /tmp/thai_medium.tar.gz -C /tmp

# После распаковки получаем SQL-файл, например /tmp/thai.sql <- https://github.com/aeuge/postgres16book/tree/main/database
# Импортируем SQL в PostgreSQL
PGPASSWORD="postgres" psql -U postgres -d thai -f /tmp/thai.sql

echo "data imported successfully!"