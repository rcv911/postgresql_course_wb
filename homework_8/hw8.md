# ДЗ-8:

## Задание:

1. Сгенерировать таблицу с 1 млн JSONB документов
2. Создать индекс
3. Обновить 1 из полей в json
4. Убедиться в блоатинге TOAST
5. Придумать методы избавится от него и проверить на практике
6. Не забываем про блоатинг индексов*

---

## Ответ:

1. Простенькая табличка
```postgresql
create table json_data (
    id serial primary key,
    data jsonb
);

-- заполнение -> 1,000,000 rows affected in 2 s 858 ms
insert into json_data (data)
select jsonb_build_object(
               'name', 'User ' || i,
               'age', (random() * 50 + 18)::int
       )
from generate_series(1, 1000000) as s(i);
```
2. Создал индекс на поле `name` для более быстрого поиска по одному из полей. Можно было повесить GIN на всю `data` как в лекции
```postgresql
create index json_data_name_idx on json_data ((data->>'name'));
```
3. Обновим часть записей (10%), например, поле `age` увеличим на 1
```postgresql
update json_data
set data = jsonb_set(data, '{age}', ((data->>'age')::int + 1)::text::jsonb)
where id % 10 = 0;
```
4. Проверяем наличие TOAST-блоатинга. Селект покажет сколько места в таблице занято неиспользуемыми данными
```postgresql
create extension if not exists pgstattuple;

select * from pgstattuple('json_data');
```

| table\_len | tuple\_count | tuple\_len | tuple\_percent | dead\_tuple\_count | dead\_tuple\_len | dead\_tuple\_percent | free\_space | free\_percent |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 92905472 | 1000000 | 75888896 | 81.68 | 100000 | 7588895 | 8.17 | 188788 | 0.2 |

- Нас тут интересуют поля:
  - `dead_tuple_len` = 100000 мёртвые записи, те самые 10%, которые мы обновляли
  - `dead_tuple_percent` = 8.17, пока значение невысокое. Высокое значение говорит о значительном блоатинге
  - `free_percent` = 0.2 маленькое значение

- Попробую обновить все записи и снова посмотреть статистику
```postgresql
update json_data
set data = jsonb_set(data, '{age}', ((data->>'age')::int + 2)::text::jsonb)
```

| table\_len | tuple\_count | tuple\_len | tuple\_percent | dead\_tuple\_count | dead\_tuple\_len | dead\_tuple\_percent | free\_space | free\_percent |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 169779200 | 1000000 | 75888896 | 44.7 | 0 | 0 | 0 | 81195212 | 47.82 |

- Вот тут интересно, что по 0 мёртвые записи, НО, `free_percent` = 47.82, почти половина свободного пространства в % -> много неиспользуемых байтов, что указывает на блоатинг
- Ещё надо проверить индекс
```postgresql
select * from pgstatindex('json_data_name_idx');
```

| version | tree\_level | index\_size | root\_block\_no | internal\_pages | leaf\_pages | empty\_pages | deleted\_pages | avg\_leaf\_density | leaf\_fragmentation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 4 | 2 | 63102976 | 209 | 39 | 7663 | 0 | 0 | 45.21 | 49.99 |

- Что нас интересует:
  - `deleted_pages` = сейчас 0. Если не 0, это указывает на блоатинг, так как индекс содержит неиспользуемые страницы
  - `avg_leaf_density` = 45.21 %. Чем ниже значение, тем больше "пустого" места в листовых страницах = блоатинг
  - `leaf_fragmentation` = 49.99 %. Высокая фрагментация указывает на то, что страницы индекса разбиты на мелкие, неэффективно используемые блоки, что замедляет доступ и увеличивает размер индекса
- Ещё раз попробую обновить 10% записей и посмотреть на индекс

| version | tree\_level | index\_size | root\_block\_no | internal\_pages | leaf\_pages | empty\_pages | deleted\_pages | avg\_leaf\_density | leaf\_fragmentation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 4 | 2 | 63102976 | 209 | 39 | 7663 | 0 | 0 | 49.7 | 49.99 |
- Ничего не поменялось
5. Уменьшение блоатинга
   - `vacuum full json_data;` = блок таблицы на время операции
   - `reindex index json_data_name_idx;`
- Сделал reindex
6. Смотрим статистику

| version | tree\_level | index\_size | root\_block\_no | internal\_pages | leaf\_pages | empty\_pages | deleted\_pages | avg\_leaf\_density | leaf\_fragmentation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 4 | 2 | 31563776 | 209 | 20 | 3832 | 0 | 0 | 90.02 | 0 |

- `avg_leaf_density` = 90.02 % после чистки. Хороший результат
- `leaf_fragmentation` = 0 %. Супер


