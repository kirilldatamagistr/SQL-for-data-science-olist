


-- Уровень 1 — Основы SQL
 

--                    Первое знакомство с заказами

-- Выведи первые 20 заказов, которые были доставлены (status = delivered). 
-- Покажи только order_id, customer_id и order_purchase_timestamp. 
-- Отсортируй по дате покупки от новых к старым.
-- Подсказка: Используй WHERE, ORDER BY DESC, LIMIT



select order_id, 
       customer_id, 
       order_purchase_timestamp
from  becom.olist_orders_dataset
where  order_status = 'delivered'
order  by order_purchase_timestamp 
limit  20
;



--                     Уникальные штаты покупателей

-- Найди все уникальные штаты (customer_state), из которых делали заказы. Отсортируй
-- алфавитно. Также выведи общее количество уникальных штатов.
-- Подсказка: Используй DISTINCT и COUNT(DISTINCT ...)


-- 1 вариант (более сложный, но точнее)

with customer_order_all as (
	
	select *
		from becom.olist_customers_dataset 
		join becom.olist_orders_dataset 
		on   becom.olist_customers_dataset.customer_id = 
	    	     becom.olist_orders_dataset.customer_id 
	)
	
	
select count(distinct customer_state) AS total_states
from customer_order_all	
	
select distinct customer_state
from customer_order_all
order by customer_state	
		
select customer_state , count(order_id) AS order_count
from customer_order_all
group by customer_state
order by order_count desc
	


--                     Сегментация товаров по цене

-- Для каждого товара из order_items создай столбец price_segment:  
-- "budget" (до 50), "mid"(50-200), "premium" (свыше 200). 
-- Покажи product_id, price и price_segment. 
-- Ограничь вывод 50 строками.
-- Подсказка: Используй CASE WHEN ... THEN ... ELSE ... END


select product_id, 
	   price , 
	   case 
           when price < 50               	then 'budget'
       	   when price between 50 and 200 	then 'mid'
       	   when price > 200              	then 'premium'
       end
       as price_segment
from becom.olist_order_items_dataset
order by price, price_segment


--                     Продавцы из Сан-Паулу

-- Найди всех продавцов из города Sao Paulo. 
-- Посчитай сколько их всего. 
-- Затем отдельным запросом найди продавцов у которых НЕТ указанного штата (seller_state IS NULL).

select count(seller_city)
from becom.olist_sellers_dataset
where seller_city = 'sao paulo'

select *
from becom.olist_sellers_dataset
where seller_state is null


-- Уровень 2 — Агрегация и JOIN


--                         Выручка по штатам


-- Посчитай суммарную выручку (price + freight_value)  
-- и количество заказов по каждому штату покупателя. 
-- Выведи только штаты с более чем 500 заказами. Отсортируй по выручке по убыванию.
-- Подсказка: JOIN orders + customers + order_items, GROUP BY, HAVING


with 
join_table as ( 
	 select oi.price,
            oi.freight_value,
            o.order_id,
            c.customer_state
	 from becom.olist_order_items_dataset as oi
	 join becom.olist_orders_dataset      as o   on oi.order_id = o.order_id
	 join becom.olist_customers_dataset   as c   on o.customer_id = c.customer_id
),
total_value as (
	 select sum(jt.price + jt.freight_value) as total_value
	 from join_table as jt  -- суммарная выручка
),
count_order_by_state as (
	 select jt.customer_state, count(jt.order_id) as count_order
	 from join_table as jt
	 group by jt.customer_state
	 order by count_order desc -- количество заказов по каждому штату покупателя
),
orders_state_500 as (
	 select *
	 from count_order_by_state 
	 where count_order > 500
	 order by count_order desc -- штаты с более чем 500 заказами
)
select *
from orders_state_500



/*
                           Средний рейтинг по категориям
                           
-- Найди среднюю оценку отзыва (review_score) для каждой категории товаров (на
английском). 
-- Покажи только категории со средним рейтингом ниже 3.5. 
-- Отсортируй от худших к лучшим.
Подсказка: JOIN 4 таблиц: order_items + products + category_translation + order_reviews
*/

with join_table as (
		select products.product_category_name              as  categ_name , 
	           order_reviews.review_score                  as  rew_score      
    		from becom.olist_order_reviews_dataset         as  order_reviews
			join becom.olist_order_items_dataset           as  order_items     on order_reviews.order_id         = order_items.order_id
			join becom.olist_products_dataset              as  products        on order_items.product_id         = products.product_id
			join becom.product_category_name_translation   as  category_name   on products.product_category_name = category_name.product_category_name 
),
	 avg_rew_score as (
		 select jt.categ_name , round(avg(jt.rew_score),1) as A
			from join_table as jt
			group by jt.categ_name -- средняя оценка отзыва для каждой категории товаров
),	
	 avg_rew_score_3 as (
		 select jt.categ_name , round(avg(jt.rew_score),1) as A
			from join_table as jt
			group by jt.categ_name
			having round(avg(jt.rew_score),1) < 3.5 
			order by A asc -- сортировка по рейтингу < 3.5 
)			
select *
	from avg_rew_score_3 
		
	
	
--                            Топ-10 продавцов
	
-- Найди топ-10 продавцов по суммарной выручке. 
-- Для каждого покажи: 
-- seller_id, город, штат, средняя сумма заказа, суммарную выручку и средний чек в штуках.
-- Подсказка: JOIN sellers + order_items, GROUP BY, ORDER BY, LIMIT

	
	
with join_table_any as (
		select sellers.seller_id , 
			   order_items.price , 
			   order_items.freight_value , 
			   order_items.order_id ,
			   order_items.order_item_id
			from becom.olist_sellers_dataset     as sellers 
			join becom.olist_order_items_dataset as order_items on sellers.seller_id = order_items.seller_id
),
	top_10_sellers as (
		select jt_any.seller_id , 
				sum(price + freight_value) as total_sum ,
				sum(price + freight_value) / count(distinct order_id) as avg_check
			from join_table_any as jt_any 
			group by jt_any.seller_id	
			order by sum(price + freight_value) desc
			limit 10
),
	top_10_sellers_all_info as (
		select sel_10.seller_id , 
				sel_10.total_sum ,
				sel_10.avg_check,
				sellers.seller_city , 
				sellers.seller_state
			from top_10_sellers                as sel_10 
			join becom.olist_sellers_dataset   as sellers  on sel_10.seller_id  = sellers.seller_id
			order by sel_10.total_sum desc
)			
		select *
			from top_10_sellers_all_info
		
			
			
							
--                             Способы оплаты
			
-- Проанализируй способы оплаты: для каждого payment_type посчитай количество транзакций,
-- суммарную и среднюю сумму платежа. 
-- Выведи также долю каждого способа от общей суммы платежей в процентах.
-- Подсказка: GROUP BY + подзапрос или оконная функция для доли
			
SELECT 
    payment_type,
    COUNT(*) AS transaction_count,
    SUM(payment_value) AS total_amount,
    AVG(payment_value) AS avg_amount,
    100.0 * SUM(payment_value) / SUM(SUM(payment_value)) OVER() AS pct_of_total
FROM becom.olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_amount DESC



-- Практические задания — Уровень 3


--                                            Топ продавца в каждой категории

-- Найди продавца с наибольшей выручкой в каждой категории товаров. 
-- Используй ROW_NUMBER() для выбора топ-1 по каждой категории. 
-- Выведи категорию, seller_id, выручку.
-- Подсказка: CTE + ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC)
	
	
WITH seller_revenue AS (
    SELECT 
        oi.seller_id,
        p.product_category_name,
        SUM(oi.price + oi.freight_value) AS revenue
    FROM becom.olist_order_items_dataset oi
    JOIN becom.olist_products_dataset p ON oi.product_id = p.product_id
    GROUP BY oi.seller_id, p.product_category_name
),
ranked AS (
    SELECT 
        product_category_name,
        seller_id,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY product_category_name ORDER BY revenue DESC) AS rn
    FROM seller_revenue
)
SELECT 
    product_category_name AS category,
    seller_id,
    round(revenue)
FROM ranked
WHERE rn = 1
ORDER BY revenue DESC;



--                              Помесячная динамика и MoM-рост


-- Посчитай количество заказов и выручку по месяцам. 
-- Добавь столбцы: заказы в прошлом месяце, выручка в прошлом месяце, 
-- Процентный прирост заказов (MoM). Покажи только 2017-2018 годы.
-- Подсказка: DATE_TRUNC + LAG() OVER (ORDER BY month) + CTE

-- 1. Количество заказов и выручку по месяцам

with new_table as (
	select i.shipping_limit_date::date as "date" ,
			i.order_id as ord_id ,
			i.price ,
			i.freight_value 
		from becom.olist_order_items_dataset as i
)
	select date_trunc('month',date) as dt ,
		   count(distinct nt.ord_id) as cnt_ord,
		   sum(nt.price + nt.freight_value) as sum_value
		from new_table as nt 
		group by date_trunc('month',date)
		order by dt 

-- 2. Добавь столбцы: заказы в прошлом месяце, 
--                    выручка в прошлом месяце, 
--                    процентный прирост заказов (MoM). 

with new_table as (
	select i.shipping_limit_date::date as "date" ,
			i.order_id as ord_id ,
			i.price ,
			i.freight_value 
		from becom.olist_order_items_dataset as i
),
	new_table_2 as 	(
		select date_trunc('month',date) as dt ,
		 count(distinct nt.ord_id) as cnt_ord,
		  sum(nt.price + nt.freight_value) as sum_value 	  
			from new_table as nt 
			group by date_trunc('month',date)
			order by dt 
), 
	new_table_3 as (
		select * , 
			lag(cnt_ord, 1) over (order by dt) as lag_1_cnt_ord,
			lag(sum_value, 1) over (order by dt) as lag_1_sum_value
		from new_table_2
)
select *,
       (cnt_ord - lag_1_cnt_ord) * 100.0 / 
       nullif(lag_1_cnt_ord, 0) as mom_cnt_ord_pct,
       (sum_value - lag_1_sum_value) * 100.0 / 
       nullif(lag_1_sum_value, 0) as mom_sum_value_pct
from new_table_3
order by dt





--                       Накопительная выручка (cumsum)

-- Рассчитай накопительную выручку нарастающим итогом по месяцам. 
-- Также добавь скользящее среднее за 3 месяца. Это классический DS-запрос для анализа тренда.
-- Подсказка: SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
--                      и ROWS BETWEEN 2 PRECEDING



with new_table as (
	select i.shipping_limit_date::date as "date" ,
			i.order_id as ord_id ,
			i.price ,
			i.freight_value 
		from becom.olist_order_items_dataset as i
),
	new_table_2 as 	(
		select date_trunc('month',date) as dt ,
		 count(distinct nt.ord_id) as cnt_ord,
		  sum(nt.price + nt.freight_value) as sum_value 	  
			from new_table as nt 
			group by date_trunc('month',date)
			order by dt
)
	select * , 
		round(sum(sum_value) over (order by dt rows unbounded preceding)) as cumsum_value ,
		round(avg(cnt_ord) over (order by dt rows between 1 preceding and 1 following )) as avg_cnt
		from new_table_2

		
		
		
--                         Квантильная сегментация покупателей
		
		
-- Разбей покупателей на 4 квартиля (NTILE) по суммарной стоимости их заказов. 
-- Посчитай средний LTV и количество клиентов в каждом квартиле. Q4 — самые ценные клиенты.
-- Подсказка: CTE для LTV + NTILE(4) OVER (ORDER BY ltv) + GROUP BY квартиль
	
		
with 
baze_table as (	
	select 
	customers.customer_id , 
	orders.order_id ,
	items.price ,
	items.freight_value
		from becom.olist_customers_dataset   as customers 
		join becom.olist_orders_dataset      as orders     on  customers.customer_id = orders.customer_id 
		join becom.olist_order_items_dataset as items      on  orders.order_id = items.order_id 
),
group_customer as (
	select 
	bz.customer_id , 
	bz.order_id , 
	round(sum(price + freight_value)) as sum_value
		from baze_table as bz
		group by bz.customer_id , bz.order_id
		order by sum_value asc
),
ntile_4 as (
	select 
	* ,
	ntile(4) over () as quartile_ntile
		from group_customer
),
customer_ltv as (
    select 
        customer_id,
        sum(sum_value) as ltv
    from ntile_4
    group by customer_id
),
stat_ltv as (
	select 
	    avg(ltv) as avg_ltv,  
	    count(*) as total_customers,
	    min(ltv) as min_ltv,
	    max(ltv) as max_ltv,
	    percentile_cont(0.5) within group (order by ltv) as median_ltv
	from customer_ltv		
),
count_customer_for_Q4 as (
	select quartile_ntile , count(*)
	from ntile_4
	group by quartile_ntile  
	order by quartile_ntile 
)
select *
from count_customer_for_Q4 -- <--  СЮДА ЗАПИСЫВЫВАЕМ НАЗВАНИЯ  
                           --      ТАБЛИЦ С ПРОМЕЖУТОЧНЫМИ 
						   --      РЕЗУЛЬТАТАМИ ДЛЯ УДОБСТВА ВЫВОДА ДАННЫХ



--                             Уровень 4 — Продвинутые DS-паттерны
--                             Практические задания — Уровень 4



--                             Воронка конверсии заказов


-- Посчитай воронку по статусам заказов: 
-- сколько заказов прошло каждый этап
 
-- created → 
--		approved → 
--  		invoiced → 
-- 				processing → 
-- 					shipped → 
-- 						delivered.
 
-- Добавь процент конверсии от предыдущего этапа.

WITH funnel AS (

  SELECT
    COUNT(DISTINCT order_id) FILTER (WHERE order_status IN ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered')) AS s1_created,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status IN ('approved', 'invoiced', 'processing', 'shipped', 'delivered')) AS s2_approved,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status IN ('invoiced', 'processing', 'shipped', 'delivered')) AS s3_invoiced,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status IN ('processing', 'shipped', 'delivered')) AS s4_processing,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status IN ('shipped', 'delivered')) AS s5_shipped,
    COUNT(DISTINCT order_id) FILTER (WHERE order_status = 'delivered') AS s6_delivered
  FROM becom.olist_orders_dataset
)
  SELECT 
  	s1_created 	  AS created,
 	s2_approved   AS approved,
  	s3_invoiced   AS invoiced,
  	s4_processing AS processing,
  	s5_shipped    AS shipped,
  	s6_delivered  AS delivered,
  
  100.0 * s2_approved   /   NULLIF(s1_created,    0)  AS conv_created_to_approved,
  100.0 * s3_invoiced   /   NULLIF(s2_approved,   0)  AS conv_approved_to_invoiced,
  100.0 * s4_processing /   NULLIF(s3_invoiced,   0)  AS conv_invoiced_to_processing,
  100.0 * s5_shipped    /   NULLIF(s4_processing, 0)  AS conv_processing_to_shipped,
  100.0 * s6_delivered  /   NULLIF(s5_shipped,    0)  AS conv_shipped_to_delivered
  
FROM funnel;




--                                        Когортный анализ Retention

-- Построй когортный анализ: для каждой месячной когорты (месяц первого заказа) 
-- посчитай сколько клиентов вернулись через 1, 2, 3 месяца. Покажи retention в процентах от размера когорты.

WITH cohorts AS (
    SELECT 
        customer_unique_id,
        DATE_TRUNC('month', MIN(orders.order_purchase_timestamp::date)) AS cohort_month
    FROM becom.olist_customers_dataset AS customer
    JOIN becom.olist_orders_dataset AS orders  
        ON customer.customer_id = orders.customer_id
    GROUP BY customer_unique_id
),
activity AS (
    SELECT 
        c.cohort_month,
        cust.customer_unique_id,
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_purchase_timestamp::date),c.cohort_month)) AS period
    FROM becom.olist_orders_dataset o
    JOIN becom.olist_customers_dataset cust ON o.customer_id = cust.customer_id
    JOIN cohorts c ON cust.customer_unique_id = c.customer_unique_id
),
cohort_size AS (
    SELECT 
        cohort_month, 
        COUNT(DISTINCT customer_unique_id) AS total
    FROM activity 
    WHERE period = 0 
    GROUP BY cohort_month
)
SELECT 
    a.cohort_month,
    a.period,
    COUNT(DISTINCT a.customer_unique_id) AS active_users,
    cs.total AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT a.customer_unique_id) / cs.total, 1) AS retention_pct
FROM activity a
JOIN cohort_size cs ON a.cohort_month = cs.cohort_month
GROUP BY a.cohort_month, a.period, cs.total
ORDER BY a.cohort_month, a.period;


------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------












		
		
