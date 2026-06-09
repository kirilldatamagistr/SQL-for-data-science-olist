# SQL-for-data-science-olist

# SQL Practice: Olist Brazilian E-Commerce Dataset

## Описание

Этот репозиторий содержит мои решения практических заданий по SQL на основе датасета **Olist Brazilian E-Commerce**. 
Задания охватывают уровни от базового синтаксиса до продвинутых DS-паттернов.

## Стек

- **СУБД:** PostgreSQL
- **Схема данных:** `becom`
- **Датасет:** Olist (9 таблиц: заказы, клиенты, товары, продавцы, отзывы, платежи, геолокация, категории)

## Структура заданий

### Уровень 1 — Основы SQL
- Первые заказы (SELECT, WHERE, ORDER BY, LIMIT)
- Уникальные штаты (DISTINCT, COUNT DISTINCT)
- Сегментация товаров по цене (CASE WHEN)
- Продавцы из Сан-Паулу (WHERE, IS NULL)

### Уровень 2 — Агрегация и JOIN
- Выручка по штатам (CTE, JOIN, GROUP BY, HAVING)
- Средний рейтинг по категориям (JOIN 4 таблиц, HAVING)
- Топ-10 продавцов (CTE, агрегация, LIMIT)
- Способы оплаты (оконная функция для доли)

### Уровень 3 — Оконные функции
- Топ продавца в каждой категории (ROW_NUMBER, PARTITION BY)
- Помесячная динамика и MoM-рост (LAG, DATE_TRUNC)
- Накопительная выручка (SUM OVER, ROWS BETWEEN)
- Квантильная сегментация клиентов (NTILE)

### Уровень 4 — Продвинутые DS-паттерны
- Воронка конверсии заказов (FILTER, UNION ALL)
- Когортный анализ Retention (CTE, DATE_TRUNC, AGE, EXTRACT)

## Ключевые навыки

- Сложные JOIN (4+ таблиц)
- CTE и цепочки CTE
- Оконные функции (ROW_NUMBER, RANK, LAG, SUM OVER)
- Когортный анализ
- Воронка конверсии
- Агрегация с FILTER
- EXTRACT, DATE_TRUNC, AGE для работы с датами
- NULLIF для безопасного деления

## Схема данных (таблицы)

| Таблица | Описание |
|---------|----------|
| `olist_customers_dataset` | Клиенты |
| `olist_orders_dataset` | Заказы |
| `olist_order_items_dataset` | Товары в заказах |
| `olist_products_dataset` | Товары |
| `olist_sellers_dataset` | Продавцы |
| `olist_order_payments_dataset` | Платежи |
| `olist_order_reviews_dataset` | Отзывы |
| `olist_geolocation_dataset` | Геолокация |
| `product_category_name_translation` | Перевод категорий |

## Автор

Решения выполнены в рамках изучения SQL для Data Science.
