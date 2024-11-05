#!/bin/bash
set -e

# Распаковываем файл
tar -xvzf /tmp/thai_medium.tar.gz -C /tmp

# Импортируем SQL в PostgreSQL
PGPASSWORD="postgres" psql -U postgres -d thai -f /tmp/thai.sql

echo "data imported successfully!"
