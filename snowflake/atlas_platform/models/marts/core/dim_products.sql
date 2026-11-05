{{
    config(
        materialized='table',
        schema='marts_core',
        tags=['mart', 'core', 'published']
    )
}}

-- Materialization: TABLE, product catalog changes infrequently so a full refresh is appropriate.
-- Read by the finance project.

SELECT
    product_id,
    product_name,
    sku,
    category,
    subcategory,
    brand,
    unit_price,
    cost_price,
    margin_pct,
    is_active,
    launch_date,
    weight_lbs,
    is_featured,
    CURRENT_TIMESTAMP()                                 AS dbt_updated_at
FROM {{ ref('catalog_products') }}
