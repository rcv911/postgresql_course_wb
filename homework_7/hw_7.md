# ДЗ-1:

## Задание:

1. Создать таблицу с продажами.
2. Реализовать функцию выбор трети года (1-4 месяц - первая треть, 5-8 - вторая и тд)
   а. через case
   b. * (бонуса в виде зачета дз не будет) используя математическую операцию (лучше 2+ варианта)
3. Проверить скорость выполнения сложного запроса (приложен в конце файла скриптов)
   с. предусмотреть NULL на входе
4. Вызвать эту функцию в SELECT из таблицы с продажами, убедиться, что всё отработало

---

## Ответ:

1. Создал табличку и заполнил рандомными данными
```postgresql
create table sales (
    sale_id serial primary key,
    sale_date timestamptz not null,
    amount numeric(10, 2) not null ,
    sku integer not null
);

insert into sales (sale_date, amount, sku)
select
   -- Случайная дата и время продажи в пределах года
   (date '2024-01-01' + (RANDOM() * 365)::int * interval '1 day')
      + (RANDOM() * interval '24 hours') as sale_date,

   ROUND((RANDOM() * (1000 - 10) + 10)::numeric, 2) as amount,
   FLOOR(RANDOM() * 1000 + 1)::int as sku
FROM
   -- Создаем 100 записей
   generate_series(1, 100) as s;
```
2. Реализовал два варианта функций по выбору трети года
```postgresql
-- функция через case
create or replace function get_year_third_case(sale_date timestamptz)
    returns integer as $$
begin
    return case
         when sale_date is null then null
         when EXTRACT(month from sale_date) between 1 and 4 then 1
         when EXTRACT(month from sale_date) between 5 and 8 then 2
         else 3
    end;
end;
$$ language plpgsql;

-- функция через математическую операцию
create or replace function get_year_third_math(sale_date timestamptz)
    returns integer as $$
begin
    return case
        when sale_date is null then null
        else CEIL(EXTRACT(month from sale_date) / 4.0)
    end;
end;
$$ language plpgsql;

-- отдельно добавил строчку с null
insert into sales (sale_date, amount, sku) values (null, 111.11, 111); 
```
3. Проверил запрос (сделал свой, потому что не нашел в файле..):
```postgresql
select
   sale_id,
   sale_date,
   get_year_third_case(sale_date) AS third_case,
   get_year_third_math(sale_date) AS third_math
from sales;
```
- Индексы не создавал на таблицу, плюс данных всего 100 записей. Если сгенерировать ещё 10млн строчек, то без индексов не обойтись, естественно 
```text
Seq Scan on sales  (cost=0.00..52.00 rows=100 width=20) (actual time=0.472..0.734 rows=101 loops=1)
Planning Time: 0.246 ms
Execution Time: 1.015 ms
```
4. Результат (сократил таблицу для читаемости):

| sale\_id | sale\_date                        | third\_case | third\_math |
|:---------|:----------------------------------|:------------|:------------|
| 101      | null                              | null        | null        |
| 65       | 2024-01-01 09:37:10.338266 +00:00 | 1           | 1           |
| 66       | 2024-01-07 09:15:28.630464 +00:00 | 1           | 1           |
| ...      | ...                               | ...         | ...         |
| 5        | 2024-04-29 07:10:04.201737 +00:00 | 1           | 1           |
| 75       | 2024-04-29 18:06:15.466986 +00:00 | 1           | 1           |
| 38       | 2024-05-02 00:52:13.865446 +00:00 | 2           | 2           |
| 56       | 2024-05-06 14:17:19.645775 +00:00 | 2           | 2           |
| ...      | ...                               | ...         | ...         |
| 70       | 2024-08-17 09:19:22.722016 +00:00 | 2           | 2           |
| 96       | 2024-08-30 04:01:09.765816 +00:00 | 2           | 2           |
| 69       | 2024-09-02 06:18:36.871960 +00:00 | 3           | 3           |
| 87       | 2024-09-06 14:57:17.129964 +00:00 | 3           | 3           |
| ...      | ...                               | ...         | ...         |
| 62       | 2024-12-28 09:06:05.968634 +00:00 | 3           | 3           |
| 52       | 2024-12-28 10:16:01.020542 +00:00 | 3           | 3           |
