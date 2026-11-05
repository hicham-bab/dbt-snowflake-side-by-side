-- =============================================================================
-- 00_shared_raw.sql
-- Shared raw data for BOTH sides of the demo (dbt platform and dbt Projects on
-- Snowflake). Same data, same warehouse size, so the comparison stays fair.
-- Run once as a role that can create databases (e.g. SYSADMIN). ~2 min on XS.
-- This file is NOT counted in the setup-weight comparison: both sides need it.
-- =============================================================================

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS ATLAS_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
USE WAREHOUSE ATLAS_WH;

CREATE DATABASE IF NOT EXISTS ATLAS_RAW;
CREATE SCHEMA IF NOT EXISTS ATLAS_RAW.ECOMMERCE;
USE SCHEMA ATLAS_RAW.ECOMMERCE;

-- Customers: 12,000 profiles
CREATE OR REPLACE TABLE RAW_CUSTOMERS AS
WITH g AS (
  SELECT seq4() + 1 AS customer_id, seq4() AS s FROM TABLE(GENERATOR(ROWCOUNT => 12000))
)
SELECT
  customer_id,
  DECODE(MOD(s, 10), 0,'Emma',1,'Liam',2,'Olivia',3,'Noah',4,'Ava',5,'William',6,'Sophia',7,'James',8,'Isabella',9,'Oliver') AS first_name,
  DECODE(MOD(s, 10), 0,'Smith',1,'Johnson',2,'Williams',3,'Brown',4,'Jones',5,'Garcia',6,'Miller',7,'Davis',8,'Martinez',9,'Lee') AS last_name,
  'customer' || customer_id || '@example.com' AS email,
  DECODE(MOD(s, 6), 0,'New York',1,'Los Angeles',2,'Chicago',3,'Houston',4,'Phoenix',5,'Philadelphia') AS city,
  DECODE(MOD(s, 6), 0,'NY',1,'CA',2,'IL',3,'TX',4,'AZ',5,'PA') AS state,
  CASE WHEN MOD(s, 100) < 5 THEN 'VIP' WHEN MOD(s, 100) < 25 THEN 'Premium'
       WHEN MOD(s, 100) < 60 THEN 'Regular' ELSE 'Budget' END AS customer_segment,
  DECODE(MOD(s, 4), 0,'paid_search',1,'paid_social',2,'organic',3,'referral') AS acquisition_channel,
  DATEADD('day', -UNIFORM(1, 1460, RANDOM(42)), cast('2026-06-01' as date)) AS acquisition_date,
  UNIFORM(18, 65, RANDOM(7)) AS age,
  IFF(MOD(s, 2) = 0, 'M', 'F') AS gender,
  TRUE AS is_email_subscribed,
  MOD(s, 100) < 35 AS is_sms_subscribed,
  CURRENT_TIMESTAMP() AS created_at,
  CURRENT_TIMESTAMP() AS updated_at
FROM g;

-- Orders: ~300K, June 2026 to June 2027 with holiday seasonality
CREATE OR REPLACE TABLE RAW_ORDERS AS
WITH g AS (
  SELECT seq4() + 1 AS order_id, MOD(seq4(), 100) AS b FROM TABLE(GENERATOR(ROWCOUNT => 300000))
), o AS (
  SELECT
    order_id,
    DATEADD('day',
      CASE WHEN b < 4  THEN UNIFORM(177, 183, RANDOM())   -- BFCM
           WHEN b < 20 THEN UNIFORM(153, 213, RANDOM())   -- holiday season
           WHEN b < 28 THEN UNIFORM(214, 244, RANDOM())   -- January
           WHEN b < 35 THEN UNIFORM(244, 319, RANDOM())   -- spring
           ELSE UNIFORM(0, 379, RANDOM()) END,
      cast('2026-06-01' as date)) AS order_date,
    UNIFORM(1, 12000, RANDOM()) AS customer_id,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 38 THEN 20
         WHEN UNIFORM(1, 100, RANDOM()) <= 55 THEN 21
         ELSE UNIFORM(1, 19, RANDOM()) END AS store_id,
    CASE WHEN b < 8 THEN 'cancelled' WHEN b < 15 THEN 'returned' ELSE 'completed' END AS status,
    IFF(MOD(order_id, 100) < 22, ROUND(UNIFORM(5.0, 30.0, RANDOM()), 2), 0) AS discount_amount,
    DECODE(MOD(order_id, 5), 0,'credit_card',1,'debit_card',2,'paypal',3,'apple_pay',4,'google_pay') AS payment_method,
    IFF(MOD(order_id, 100) < 32, UNIFORM(1, 30, RANDOM()), NULL) AS campaign_id,
    DECODE(MOD(order_id, 7), 0,'paid_search',1,'paid_social',2,'organic',3,'email',4,'direct',5,'affiliate',6,'referral') AS traffic_source,
    UNIFORM(1, 5, RANDOM()) AS item_count
  FROM g
)
SELECT
  order_id, order_date, customer_id, store_id, status,
  cast(discount_amount as number(10,2)) AS discount_amount,
  payment_method, campaign_id, traffic_source, item_count,
  DATEADD('minute', UNIFORM(0, 1380, RANDOM()), cast(order_date as timestamp_ntz)) AS ordered_at,
  CURRENT_TIMESTAMP() AS _loaded_at
FROM o
WHERE order_date BETWEEN '2026-06-01' AND '2027-06-15';

-- Order items: one row per line, honoring item_count. Unit prices mirror the
-- catalog_products seed (80 SKUs) with +/-5% variance at purchase time.
CREATE OR REPLACE TABLE RAW_ORDER_ITEMS AS
WITH catalog_prices (product_id, unit_price) AS (
  SELECT * FROM VALUES
    (1, 89.99),
    (2, 149.99),
    (3, 59.99),
    (4, 39.99),
    (5, 119.99),
    (6, 149.99),
    (7, 49.99),
    (8, 299.99),
    (9, 199.99),
    (10, 119.99),
    (11, 129.99),
    (12, 199.99),
    (13, 349.99),
    (14, 89.99),
    (15, 49.99),
    (16, 119.99),
    (17, 159.99),
    (18, 34.99),
    (19, 44.99),
    (20, 89.99),
    (21, 89.99),
    (22, 35.99),
    (23, 79.99),
    (24, 55.99),
    (25, 49.99),
    (26, 69.99),
    (27, 64.99),
    (28, 24.99),
    (29, 22.99),
    (30, 59.99),
    (31, 29.99),
    (32, 24.99),
    (33, 34.99),
    (34, 59.99),
    (35, 39.99),
    (36, 79.99),
    (37, 54.99),
    (38, 19.99),
    (39, 18.99),
    (40, 44.99),
    (41, 34.99),
    (42, 79.99),
    (43, 22.99),
    (44, 49.99),
    (45, 29.99),
    (46, 24.99),
    (47, 39.99),
    (48, 34.99),
    (49, 49.99),
    (50, 29.99),
    (51, 44.99),
    (52, 24.99),
    (53, 24.99),
    (54, 49.99),
    (55, 29.99),
    (56, 18.99),
    (57, 34.99),
    (58, 22.99),
    (59, 19.99),
    (60, 39.99),
    (61, 28.99),
    (62, 22.99),
    (63, 32.99),
    (64, 19.99),
    (65, 34.99),
    (66, 59.99),
    (67, 189.99),
    (68, 99.99),
    (69, 299.99),
    (70, 449.99),
    (71, 149.99),
    (72, 59.99),
    (73, 89.99),
    (74, 94.99),
    (75, 79.99),
    (76, 29.99),
    (77, 29.99),
    (78, 79.99),
    (79, 89.99),
    (80, 59.99)
), lines AS (
  SELECT o.order_id, o.item_count, o.discount_amount, n.line_no
  FROM RAW_ORDERS o
  JOIN (SELECT seq4() + 1 AS line_no FROM TABLE(GENERATOR(ROWCOUNT => 5))) n
    ON n.line_no <= o.item_count
), picked AS (
  SELECT
    order_id, item_count, discount_amount, line_no,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN UNIFORM(1, 20, RANDOM())
         WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN UNIFORM(21, 50, RANDOM())
         ELSE UNIFORM(51, 80, RANDOM()) END AS product_id,
    UNIFORM(1, 4, RANDOM()) AS quantity,
    UNIFORM(-0.05, 0.05, RANDOM()) AS price_variance
  FROM lines
), priced AS (
  SELECT
    l.*,
    ROUND(c.unit_price * (1 + l.price_variance), 2) AS unit_price_at_purchase,
    ROUND(l.discount_amount / l.item_count, 2) AS line_discount
  FROM picked l
  JOIN catalog_prices c ON c.product_id = l.product_id
)
SELECT
  ROW_NUMBER() OVER (ORDER BY order_id, line_no) AS order_item_id,
  order_id,
  product_id,
  quantity,
  cast(unit_price_at_purchase as number(10,2)) AS unit_price_at_purchase,
  cast(unit_price_at_purchase * quantity as number(12,2)) AS line_gross_revenue,
  cast(unit_price_at_purchase * quantity - line_discount as number(12,2)) AS line_net_revenue,
  cast(line_discount as number(10,2)) AS line_discount,
  CURRENT_TIMESTAMP() AS _loaded_at
FROM priced;

-- Returns: for orders with status = 'returned'
CREATE OR REPLACE TABLE RAW_RETURNS AS
SELECT
  ROW_NUMBER() OVER (ORDER BY order_id) AS return_id,
  order_id, customer_id, store_id, order_date,
  DATEADD('day', UNIFORM(3, 21, RANDOM()), order_date) AS return_date,
  DECODE(MOD(order_id, 7), 0,'defective_item',1,'wrong_size',2,'not_as_described',3,'changed_mind',4,'arrived_late',5,'duplicate_order',6,'damaged_in_shipping') AS return_reason,
  DECODE(MOD(order_id, 3), 0,'refund_to_original',1,'store_credit',2,'exchange') AS resolution_type,
  cast(ROUND(UNIFORM(15.0, 250.0, RANDOM()), 2) as number(10,2)) AS refund_amount,
  IFF(MOD(order_id, 100) < 85, 'approved', 'denied') AS return_status,
  CURRENT_TIMESTAMP() AS _loaded_at
FROM RAW_ORDERS
WHERE status = 'returned';

SELECT 'RAW_CUSTOMERS' t, COUNT(*) n FROM RAW_CUSTOMERS UNION ALL
SELECT 'RAW_ORDERS', COUNT(*) FROM RAW_ORDERS UNION ALL
SELECT 'RAW_ORDER_ITEMS', COUNT(*) FROM RAW_ORDER_ITEMS UNION ALL
SELECT 'RAW_RETURNS', COUNT(*) FROM RAW_RETURNS;
