create schema if not exists staging;

create or replace view staging.stg_variants as
select
    r.source_file,
    r.loaded_at::date                          as snapshot_date,
    (r.v->>'id')::bigint                       as product_id,
    r.v->>'title'                              as title,
    r.v->>'vendor'                             as vendor,
    r.v->>'product_type'                       as product_type,
    r.v->'tags'                                as tags,
    (r.v->>'created_at')::timestamptz          as product_created_at,
    (var->>'id')::bigint                       as variant_id,
    var->>'sku'                                as sku,
    var->>'option1'                            as option1,
    var->>'option2'                            as option2,
    (var->>'price')::numeric                   as price,
    (var->>'compare_at_price')::numeric        as compare_at_price,
    (var->>'available')::boolean               as available
from raw.products_raw r
cross join lateral jsonb_array_elements(r.v->'variants') as var;