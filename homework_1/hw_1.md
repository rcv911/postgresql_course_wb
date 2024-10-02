# ДЗ-1:

## Задание:

1. Развернуть ВМ (Linux) с PostgreSQL
2. Залить Тайские перевозки https://github.com/aeuge/postgres16book/tree/main/database
3. Посчитать количество поездок: `select count(*) from book.tickets;`

---

## Ответ:

1. Развернул локально в докере
2. Накатил в БД объем порядка 60 млн. строк https://storage.googleapis.com/thaibus/thai_medium.tar.gz
3. Количество поездок = `53_997_475`
