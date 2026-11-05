{{
    config(
        materialized='table',
        schema='marts_core',
        tags=['mart', 'core', 'published'],
        access='public'
    )
}}

/*
  Materialization: TABLE, rebuilt nightly as a full refresh.
  Published as a public node for dbt Mesh consumers (finance).
  Use ref('atlas_platform', 'dim_customers') in consumer projects.

*/

SELECT
    customer_id,
    first_name,
    last_name,
    full_name,
    email,
    city,
    state,
    customer_segment,
    acquisition_channel,
    acquisition_date,
    acquisition_month,
    acquisition_quarter,
    acquisition_year,
    age,
    gender,
    is_email_subscribed,
    is_sms_subscribed,
    days_since_acquisition,
    total_orders,
    completed_orders,
    returned_orders,
    cancelled_orders,
    lifetime_gross_revenue,
    lifetime_net_revenue,
    avg_order_value,
    first_order_date,
    last_order_date,
    days_between_first_last_order,
    distinct_channels_used,
    most_common_channel,
    customer_lifecycle_stage,
    customer_value_tier,
    CURRENT_TIMESTAMP()                                 AS dbt_updated_at

FROM {{ ref('int_customers_with_orders') }}
