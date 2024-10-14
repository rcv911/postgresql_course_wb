# ДЗ-4:

## Задание:

1. Создать таблицу `accounts(id integer, amount numeric)`;
2. Добавить несколько записей и подключившись через 2 терминала добиться ситуации взаимоблокировки (deadlock).
3. Посмотреть логи и убедиться, что информация о дедлоке туда попала.

---

## Ответ:

1. Консоль:
```postgresql
create schema if not exists hw4;

create table if not exists hw4.accounts (
    id integer primary key,
    amount numeric
);
```
2. Добавил две записи
```postgresql
insert into hw4.accounts (id, amount) values (1, 100), (2, 200);
```
- терминал 1: Начал транзакцию и заблокировал запись с id = 1
```text
postgres=# begin;
BEGIN
postgres=*# update hw4.accounts set amount = amount + 50 where id = 1;
UPDATE 1
postgres=*#
```
- терминал 2: Начал транзакцию и заблокировал запись с id = 2
```text
postgres=# begin;
BEGIN
postgres=*# update hw4.accounts set amount = amount + 22 where id = 2;
UPDATE 1
postgres=*#
```
- терминал 1: Пытаюсь заблокировать запись с id = 2. Терминал висит в ожидании...
```text
postgres=*# update hw4.accounts set amount = amount + 50 where id = 2;

```
- терминал 2: Пытаюсь заблокировать запись с id = 1. Отваливаюсь по дедлоку. 
```text
postgres=*# update hw4.accounts set amount = amount + 22 where id = 1;
ERROR:  deadlock detected
DETAIL:  Process 98620 waits for ShareLock on transaction 886; blocked by process 98603.
Process 98603 waits for ShareLock on transaction 887; blocked by process 98620.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,1) in relation "accounts"
postgres=!#
```
- терминал 1: Ожидание заканчивается и дальше могу продолжить транзакцию
```text
UPDATE 1
postgres=*#
```

3. Логи:
```text
2024-10-14 20:26:10.491 UTC [98620] ERROR:  deadlock detected
2024-10-14 20:26:10.491 UTC [98620] DETAIL:  Process 98620 waits for ShareLock on transaction 886; blocked by process 98603.
	Process 98603 waits for ShareLock on transaction 887; blocked by process 98620.
	Process 98620: update hw4.accounts set amount = amount + 22 where id = 1;
	Process 98603: update hw4.accounts set amount = amount + 50 where id = 2;
2024-10-14 20:26:10.491 UTC [98620] HINT:  See server log for query details.
2024-10-14 20:26:10.491 UTC [98620] CONTEXT:  while updating tuple (0,1) in relation "accounts"
2024-10-14 20:26:10.491 UTC [98620] STATEMENT:  update hw4.accounts set amount = amount + 22 where id = 1;
```

---

- Я решил не останавливаться, закрыл транзакции в обоих терминалах
- Терминал 1: 
```text
postgres=*# end;
COMMIT
postgres=#
```
- Терминал 2:
```text
postgres=!# end;
ROLLBACK
postgres=#
```
- Посмотрел состояние таблицы. Не фиксируются данные с терминала 2 из-за дедлока. 
```text
postgres=# select * from hw4.accounts;
 id | amount
----+--------
  1 |    150
  2 |    250
(2 rows)

postgres=#
```
- Фактически, если в логах моего гошного приложения будут сообщения типа `ERROR: deadlock detected (SQLSTATE 40P01)`, то я теряю данные...




