-- verification
select count(*) from staging.stg_variants;

select count(*) as rows, count(distinct variant_id) as variants
from mart.fact_variant_snapshot;      -- rows = variants

select count(*) from mart.dim_product; -- 24095

-- 1. Category performance
select p.product_type,
       count(distinct p.product_id)            as products,
       round(avg(f.price))                     as avg_price,
       round(avg(f.discount_pct), 1)           as avg_discount_pct,
       round(100.0 * avg(f.available::int), 1) as in_stock_pct
from mart.fact_variant_snapshot f
join mart.dim_product p using (product_id)
group by 1
order by products desc;

-- 2. Price bands
select case when price < 1000 then '1. under 1000'
            when price < 2000 then '2. 1000-1999'
            when price < 3000 then '3. 2000-2999'
            else '4. 3000+' end as price_band,
       count(distinct product_id) as products
from mart.fact_variant_snapshot
group by 1 order by 1;

-- 3. Size availability
select size_or_option,
       count(*) as variants,
       round(100.0 * avg(available::int), 1) as in_stock_pct
from mart.fact_variant_snapshot
group by 1
having count(*) > 500
order by in_stock_pct;

-- 4. New launches per month
select date_trunc('month', product_created_at)::date as month,
       count(*) as new_products
from mart.dim_product
group by 1 order by 1;

-- 5. Deepest discounts
select p.title, p.product_type, max(f.discount_pct) as max_discount
from mart.fact_variant_snapshot f
join mart.dim_product p using (product_id)
group by 1, 2
order by max_discount desc
limit 20;