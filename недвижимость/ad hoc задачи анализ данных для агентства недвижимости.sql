/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Торгашина Ангелина
 * Дата: 30.10.2024
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- Напишите ваш запрос здесь

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
    segment as (select id, 
    case 
	when days_exposition between 1 and 30 then 'до месяца'
	when days_exposition between 31 and 90 then 'до 3 месяцев'
	when days_exposition between 91 and 180 then 'до полугода'
	when days_exposition>180 then 'более полугода'
	else 'непроданные объекты'
end as activity_duration
from real_estate.advertisement)
SELECT
case 
	when city='Санкт-Петербург' then 'Санкт-Петербург' 
	else 'Ленобласть'
end as region,
activity_duration,
round(count(id)/(select count (id) from real_estate.flats where id in (select * from filtered_id) and type_id='F8EM')::numeric,2) as ads_share,
round(avg(last_price/total_area)::numeric,2) as avg_price_per_square_meters,
round(avg(total_area)::numeric,2) as avg_total_area,
percentile_disc(0.5) within group (order by rooms) as median_rooms,
percentile_cont(0.5) within group (order by balcony) as median_balcony,
percentile_cont(0.5) within group (order by floor) as median_floor
FROM real_estate.flats
left join real_estate.city using(city_id)
left join real_estate.advertisement using (id)
left join segment using(id)
WHERE id IN (SELECT * FROM filtered_id) and type_id='F8EM'
group by region, activity_duration

-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

-- Напишите ваш запрос здесь
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
    segments as (select id,
    first_day_exposition, 
    extract (month from first_day_exposition) as month_number,
	case
    when extract (month from first_day_exposition)=1 then 'январь'
	when extract (month from first_day_exposition)=2 then 'февраль'
	when extract (month from first_day_exposition)=3 then 'март'
	when extract (month from first_day_exposition)=4 then 'апрель'
	when extract (month from first_day_exposition)=5 then 'май'
	when extract (month from first_day_exposition)=6 then 'июнь'
	when extract (month from first_day_exposition)=7 then 'июль'
	when extract (month from first_day_exposition)=8 then 'август'
	when extract (month from first_day_exposition)=9 then 'сентябрь'
	when extract (month from first_day_exposition)=10 then 'октябрь'
	when extract (month from first_day_exposition)=11 then 'ноябрь'
	when extract (month from first_day_exposition)=12 then 'декабрь'
end as months,
extract (month from first_day_exposition),
extract (month from (first_day_exposition+ '1 day'::interval*days_exposition)) as removing_ads_date,
last_price
from real_estate.advertisement 
)
SELECT rank() over (order by count(first_day_exposition) desc) as activity_rank_publication,
rank() over (order by count(removing_ads_date) desc) as activity_rank_removing,
month_number,
months,
count(first_day_exposition) as first_day_exposition_count,
count(removing_ads_date) as removing_ads_date_count,
avg(last_price/total_area)::numeric(10,2) as avg_price_per_square_metre,
avg(total_area)::numeric(10,2) as avg_total_area
FROM segments
left join real_estate.flats as f using(id)
WHERE id IN (SELECT * FROM filtered_id) and f.type_id='F8EM'
group by months, month_number;
-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

-- Напишите ваш запрос здесь
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
    main_table as (select ntile(4) over(order by avg(days_exposition)) as duration_groups,
case 
	when avg(days_exposition) between 1 and 105 then 'до 105 дней'
	when avg(days_exposition) between 105 and 201 then 'до 201 дня' 
	when avg(days_exposition) between 201 and 361 then 'до 361'
	else 'больше 361 дня или не проданные'
end as ads_segments,
type,
city,
count(a.id) as quantity_of_ads,
avg(days_exposition)::numeric(10,2) as avg_ads_duration,
round(count(a.id) filter (where days_exposition is not null)/count(a.id)::numeric, 2) as share_of_sold_flats,
round(avg(last_price/total_area)::numeric,2) as avg_price_per_square_meters,
round(avg(total_area)::numeric,2) as avg_total_area,
percentile_cont(0.5) within group (order by rooms) as median_rooms,
percentile_disc(0.5) within group (order by balcony) as median_balcony,
percentile_cont(0.5) within group (order by floor) as median_floor
FROM real_estate.flats
left join real_estate.city using(city_id)
left join real_estate.advertisement as a using (id)
left join real_estate.type using(type_id)
WHERE id IN (SELECT * FROM filtered_id) and city<>'Санкт-Петербург'
group by type,city)
select *
from main_table 
where quantity_of_ads>=50