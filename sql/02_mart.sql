create schema if not exists mart;

drop table if exists mart.dim_product;
create table mart.dim_product as
select distinct on (product_id)
       product_id, title, vendor, product_type, product_created_at
from staging.stg_variants
order by product_id, snapshot_date desc;

drop table if exists mart.fact_variant_snapshot;
create table mart.fact_variant_snapshot as
select distinct on (variant_id, snapshot_date)
       variant_id, product_id, snapshot_date, sku,
       option1 as size_or_option,
       price, compare_at_price, available,
       case when compare_at_price > price
            then round(100.0 * (compare_at_price - price) / compare_at_price, 1)
            else 0 end as discount_pct
from staging.stg_variants
order by variant_id, snapshot_date, source_file desc;

create index on mart.fact_variant_snapshot (product_id, snapshot_date);