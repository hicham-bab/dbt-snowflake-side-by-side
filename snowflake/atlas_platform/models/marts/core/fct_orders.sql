{{
    config(
        materialized='table',
        schema='marts_core',
        cluster_by=['order_date', 'store_id'],
        tags=['mart', 'core', 'published']
    )
}}

/*
  Materialization: TABLE, rebuilt on every run (300K rows, seconds on XS).
  cluster_by ['order_date', 'store_id'] enables efficient pruning on Snowflake.

  This is the central fact table for the platform, consumed by
  atlas_finance, which re-declares it as a source (no cross-project ref on Snowflake).
*/

WITH orders AS (
    SELECT * FROM {{ ref('int_orders_enriched') }}
)

SELECT
    cast(order_id as number(38,0))                     AS order_id,
    cast(order_date as date)                           AS order_date,
    cast(ordered_at as timestamp_ntz)                  AS ordered_at,
    cast(customer_id as number(38,0))                  AS customer_id,
    cast(store_id as number(38,0))                     AS store_id,
    cast(store_name as varchar)                        AS store_name,
    cast(store_type as varchar)                        AS store_type,
    cast(store_channel as varchar)                     AS store_channel,
    cast(store_city as varchar)                        AS store_city,
    cast(store_state as varchar)                       AS store_state,
    cast(store_region as varchar)                      AS store_region,
    cast(order_status as varchar)                      AS order_status,
    cast(is_completed as boolean)                      AS is_completed,
    cast(is_returned as boolean)                       AS is_returned,
    cast(is_cancelled as boolean)                      AS is_cancelled,
    cast(payment_method as varchar)                    AS payment_method,
    cast(campaign_id as number(38,0))                  AS campaign_id,
    cast(traffic_source as varchar)                    AS traffic_source,
    cast(has_discount as boolean)                      AS has_discount,
    cast(order_level_discount as number(10,2))         AS discount_amount,
    cast(item_count as number(38,0))                   AS item_count,
    cast(order_month as date)                          AS order_month,
    cast(order_week as date)                           AS order_week,
    cast(order_quarter as number(38,0))                AS order_quarter,
    cast(order_year as number(38,0))                   AS order_year,
    cast(gross_revenue as number(18,2))                AS gross_revenue,
    cast(net_revenue as number(18,2))                  AS net_revenue,
    cast(total_units as number(38,0))                  AS total_units,
    cast(distinct_products as number(38,0))            AS distinct_products,
    cast(estimated_tax as number(18,2))                AS estimated_tax,
    cast(refund_amount as number(10,2))                AS refund_amount,
    cast(return_reason as varchar)                     AS return_reason,
    cast(return_date as date)                          AS return_date,
    cast(has_return as boolean)                        AS has_return,

    -- Revenue net of returns
    cast(
        CASE
            WHEN is_returned AND has_return
            THEN GREATEST(net_revenue - COALESCE(refund_amount, 0), 0)
            ELSE net_revenue
        END
    as number(18,2))                                   AS realized_revenue,

    cast(_loaded_at as timestamp_ltz)                  AS _loaded_at,
    cast(CURRENT_TIMESTAMP() as timestamp_ltz)         AS dbt_updated_at

FROM orders
