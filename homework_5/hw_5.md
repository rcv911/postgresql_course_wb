# ДЗ-1:

## Задание:

1. Развернуть асинхронную реплику (можно использовать 1 ВМ, просто рядом кластер развернуть и подключиться через localhost): тестируем производительность по сравнению с сингл инстансом. Эталонного решения не будет, так как всё показано на лекции. 
2. Задание со * переделать:
   - а) под синхронную реплику 
   - б) синхронная реплика + асинхронная каскадно снимаемая с синхронной 
3. Задание с **: переделать скрипты для ВМ или докера из моей репы с pg_rewind под 17 ПГ https://github.com/aeuge/pg_rewind

---

## Ответ:

1. Развернул в докере мастер и асинхронную реплику. Конфиг в папке [deploy](./deploy) в файле `docker-compose-async-replica.yaml`
    - Накатил в БД объем порядка 60 млн. строк https://storage.googleapis.com/thaibus/thai_medium.tar.gz
    - Проверил состояние репликации - `select * from pg_stat_replication` -> `sync_state = async`
---

### Тестируем запись: 

- Зашел внутрь мастера `docker exec -it pg_master /bin/bash`
- Создал скрипт
```shell
        cat > /tmp/workload2.sql << EOL
        INSERT INTO book.tickets (fkRide, fio, contact, fkSeat)
        VALUES (
          ceil(random()*100),
          (array(SELECT fam FROM book.fam))[ceil(random()*110)]::text || ' ' ||
          (array(SELECT nam FROM book.nam))[ceil(random()*110)]::text,
          ('{"phone":"+7' || (1000000000::bigint + floor(random()*9000000000)::bigint)::text || '"}')::jsonb,
          ceil(random()*100)
        );
        EOL
```
- Прогнал на pgbench:
```shell
     pgbench -c 8 -j 4 -T 10 -f /tmp/workload2.sql -n -U postgres -p 5432 -d thai
```
- Получил `tps = 15_487`
```text
         pgbench (17.0)
         transaction type: /tmp/workload2.sql
         scaling factor: 1
         query mode: simple
         number of clients: 8
         number of threads: 4
         maximum number of tries: 1
         duration: 10 s
         number of transactions actually processed: 154344
         number of failed transactions: 0 (0.000%)
         latency average = 0.517 ms
         initial connection time = 35.098 ms
         tps = 15486.662841 (without initial connection time)
  ```
  - Тест на async реплике не получится провести, по понятным причинам: `cannot execute INSERT in a read-only transaction`
---

### Тестируем чтение:

- Мастер 
```shell
        cat > /tmp/workload.sql << EOL
        \set r random(1, 5000000)
        SELECT id, fkRide, fio, contact, fkSeat FROM book.tickets WHERE id = :r;
        EOL
```
- Прогнал на pgbench:
```shell
        pgbench -c 8 -j 4 -T 10 -f /tmp/workload.sql -n -U postgres -p 5432 -d thai
```
- Получил `tps = 77_796`
```text
        pgbench (17.0)
        transaction type: /tmp/workload.sql
        scaling factor: 1
        query mode: simple
        number of clients: 8
        number of threads: 4
        maximum number of tries: 1
        duration: 10 s
        number of transactions actually processed: 775128
        number of failed transactions: 0 (0.000%)
        latency average = 0.103 ms
        initial connection time = 37.693 ms
        tps = 77796.539539 (without initial connection time) 
```
- Теперь такой же тест на чтение для async реплики
- Получил `tps = 80_872`. Близкое значение к мастеру, на лекции тоже в целом небольшая погрешность была
```text
        pgbench (17.0)
        transaction type: /tmp/workload.sql
        scaling factor: 1
        query mode: simple
        number of clients: 8
        number of threads: 4
        maximum number of tries: 1
        duration: 10 s
        number of transactions actually processed: 805942
        number of failed transactions: 0 (0.000%)
        latency average = 0.099 ms
        initial connection time = 35.978 ms
        tps = 80872.206296 (without initial connection time)
```
