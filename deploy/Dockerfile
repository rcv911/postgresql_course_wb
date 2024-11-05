FROM postgres:17

# Устанавливаем wget
RUN apt-get update && apt-get install -y wget

# Копируем скрипты для инициализации
COPY ./init-scripts /docker-entrypoint-initdb.d/