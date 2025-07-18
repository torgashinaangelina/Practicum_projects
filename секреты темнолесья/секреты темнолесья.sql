/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Ангелина Торгашина
 * Дата: 20.10.2024
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT COUNT (id) AS users_count,
SUM (payer) AS payers_count,
AVG (payer) AS payer_share
FROM fantasy.users
WHERE payer=1 OR payer=0;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
WITH share AS (SELECT DISTINCT race_id,
race,
AVG(payer) OVER (PARTITION BY race_id) AS payer_share_race
FROM fantasy.users
LEFT JOIN fantasy.race USING(race_id))
SELECT race, 
SUM (payer) AS payers_count,
COUNT (payer) AS users_count,
ROUND(payer_share_race,4)
FROM fantasy.users
LEFT JOIN share USING (race_id)
GROUP BY race, payer_share_race
ORDER BY payers_count;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT COUNT(amount) AS quantity_of_purchases,
SUM(amount) AS sum_of_purchases,
MIN(amount) AS min_purchase,
MAX(amount) AS max_purchase,
AVG(amount)::NUMERIC(10, 2) AS avg_purchase,
percentile_cont(0.5) WITHIN GROUP (ORDER BY amount)::NUMERIC(10, 2) AS mid_purchase, 
stddev(amount)::NUMERIC(10, 2) AS stddev_purchase
FROM fantasy.events
WHERE amount>0;
-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь

SELECT COUNT(amount) FILTER (WHERE amount = 0) AS zero_purchase, 
COUNT(amount) FILTER (WHERE amount = 0)/COUNT(amount)::NUMERIC AS zero_purchase_share
FROM fantasy.events; 
-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
WITH payers AS (SELECT payer,
count(DISTINCT e.id) AS total_users,
count(DISTINCT e.transaction_id)purchases_count,
sum(e.amount) AS purchase_sum
FROM fantasy.users AS u
LEFT JOIN FANTASY.events AS e USING (id)
WHERE payer=1 AND amount>0
GROUP BY payer),
non_payers AS (SELECT payer,
count(DISTINCT e.id) AS total_users,
count(DISTINCT e.transaction_id) AS count_purchases,
sum(e.amount) AS purchase_sum
FROM fantasy.users AS u
LEFT JOIN FANTASY.events AS e USING (id)
WHERE payer=0 AND amount>0
GROUP BY payer)
SELECT CASE WHEN payer=1
THEN 'payer' END AS player_status, 
total_users,
purchases_count/total_users::NUMERIC AS avg_purchases_count,
purchase_sum/total_users AS avg_purchase_sum
FROM payers
UNION ALL
SELECT CASE WHEN payer=0
THEN 'non-payer' END AS player_status,
total_users,
count_purchases/total_users::numeric AS avg_purchases_count,
purchase_sum/total_users AS avg_purchase_sum
FROM non_payers;
-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH sales AS (SELECT item_code,
game_items,
COUNT(item_code) AS total_item_sales,
(SELECT COUNT(*) AS total_sales FROM fantasy.events WHERE amount>0)
FROM fantasy.events
LEFT JOIN fantasy.items using(item_code)
WHERE amount>0
GROUP BY item_code,game_items),
persons_share AS (SELECT item_code,
count (DISTINCT id) AS total_buyers_per_item,
(SELECT count(DISTINCT id) AS total_buyers FROM fantasy.events WHERE amount>0)
FROM fantasy.events
WHERE amount>0
GROUP BY item_code)
SELECT game_items,
total_item_sales,
total_sales,
total_item_sales/total_sales::NUMERIC AS item_sales_share,
total_buyers_per_item/total_buyers::NUMERIC AS buyer_per_item_share
FROM sales
LEFT JOIN persons_share USING (item_code)
ORDER BY total_item_sales DESC 
-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH aa AS (SELECT race_id,
race,
count(DISTINCT e.id) AS buyers_per_race,
count(transaction_id) AS purchases_per_races,
AVG(amount) AS avg_amount
FROM fantasy.events AS e
LEFT JOIN fantasy.users USING (id)
LEFT JOIN fantasy.race using(race_id)
WHERE amount>0
GROUP BY race_id,race)
SELECT race,
count(DISTINCT u.id) AS total_players_per_race,
buyers_per_race,
buyers_per_race/count(DISTINCT u.id)::NUMERIC(10, 2) AS buyers_share_per_race,
count(DISTINCT id) FILTER (WHERE payer=1 AND amount>0)/buyers_per_race::NUMERIC(10, 2) payers_share_per_race,
purchases_per_races/buyers_per_race::NUMERIC(10, 2) AS avg_quantity_of_purchases_per_player,
avg_amount::NUMERIC(10, 2) AS avg_amount_of_one_purchase_per_player,
sum(amount) FILTER (WHERE amount>0)/buyers_per_race::NUMERIC(10, 2) AS avg_amount_of_all_purchases_per_player
FROM fantasy.users AS u
LEFT JOIN aa USING (race_id)
LEFT JOIN fantasy.events AS e USING (id)
GROUP BY race,buyers_per_race,purchases_per_races,avg_amount

