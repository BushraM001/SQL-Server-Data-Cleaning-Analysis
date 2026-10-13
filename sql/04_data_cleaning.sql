/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 04_data_cleaning.sql
  Purpose: Remove exact duplicates, standardize values,
           convert data types, flag invalid values, and create
           canonical customer mappings
==============================================================*/

USE CustomerOrdersAnalytics;
GO

/*--------------------------------------------------------------
  1. Clean Customers
--------------------------------------------------------------*/

DROP TABLE IF EXISTS clean_customers;
GO

WITH customer_dedup AS
(SELECT *,ROW_NUMBER() OVER (PARTITION BY customer_id, first_name, last_name, email,
                			phone, city, state, signup_date
            				ORDER BY customer_id) AS rn
 FROM raw_customers
)
SELECT customer_id,
    TRIM(first_name) AS first_name, TRIM(last_name) AS last_name,
    NULLIF(TRIM(email), '') AS email, NULLIF(TRIM(phone), '') AS phone, TRIM(city) AS city,
    CASE LOWER(TRIM(state))
        WHEN 'arizona' THEN 'AZ'
        WHEN 'az' THEN 'AZ'
        WHEN 'california' THEN 'CA'
        WHEN 'ca' THEN 'CA'
        WHEN 'colorado' THEN 'CO'
        WHEN 'co' THEN 'CO'
        WHEN 'florida' THEN 'FL'
        WHEN 'fl' THEN 'FL'
        WHEN 'georgia' THEN 'GA'
        WHEN 'ga' THEN 'GA'
        WHEN 'illinois' THEN 'IL'
        WHEN 'il' THEN 'IL'
        WHEN 'new york' THEN 'NY'
        WHEN 'ny' THEN 'NY'
        WHEN 'texas' THEN 'TX'
        WHEN 'tx' THEN 'TX'
        WHEN 'washington' THEN 'WA'
        WHEN 'wa' THEN 'WA'
        ELSE UPPER(TRIM(state))
    END AS state,
    TRY_CONVERT(DATE, NULLIF(TRIM(REPLACE(signup_date, CHAR(13), '')), '')) AS signup_date
INTO clean_customers
FROM customer_dedup
WHERE rn = 1;
GO

/*--------------------------------------------------------------
  2. Clean Products
--------------------------------------------------------------*/

DROP TABLE IF EXISTS clean_products;
GO

SELECT TRIM(product_id) AS product_id, TRIM(product_name) AS product_name,
    CASE
        WHEN NULLIF(TRIM(category), '') IS NULL THEN 'Unknown'
        WHEN LOWER(TRIM(category)) IN ('electronic', 'electronics') THEN 'Electronics'
        WHEN LOWER(TRIM(category)) IN ('home', 'home goods') THEN 'Home'
        WHEN LOWER(TRIM(category)) IN ('kitchen', 'kitchenware') THEN 'Kitchen'
        WHEN LOWER(TRIM(category)) IN ('office', 'office supplies') THEN 'Office'
        WHEN LOWER(TRIM(category)) IN ('beauty', 'personal care') THEN 'Beauty'
        ELSE TRIM(category)
    END AS category,
    TRY_CONVERT(DECIMAL(10,2), NULLIF(TRIM(list_price), '')) AS list_price,
    TRY_CONVERT(DECIMAL(10,2), NULLIF(TRIM(cost), '')) AS cost,
    CASE
        WHEN LOWER(TRIM(REPLACE(active_flag, CHAR(13), ''))) IN ('y', 'yes') THEN 'Y'
        WHEN LOWER(TRIM(REPLACE(active_flag, CHAR(13), ''))) IN ('n', 'no') THEN 'N'
        ELSE NULL
    END AS active_flag
INTO clean_products
FROM raw_products;
GO

/*--------------------------------------------------------------
  3. Clean Orders
--------------------------------------------------------------*/

DROP TABLE IF EXISTS clean_orders;
GO

WITH order_dedup AS
(SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, order_date, ship_date,
                			 order_status, payment_method, shipping_state
           				 ORDER BY order_id) AS rn
 FROM raw_orders
)
SELECT TRIM(order_id) AS order_id, TRIM(customer_id) AS customer_id,
    TRY_CONVERT(DATE, NULLIF(TRIM(order_date), '')) AS order_date,
    TRY_CONVERT(DATE, NULLIF(TRIM(ship_date), '')) AS ship_date,
    TRIM(order_status) AS order_status,
    TRIM(payment_method) AS payment_method,
    CASE LOWER(TRIM(REPLACE(shipping_state, CHAR(13), '')))
        WHEN 'arizona' THEN 'AZ'
        WHEN 'az' THEN 'AZ'
        WHEN 'california' THEN 'CA'
        WHEN 'ca' THEN 'CA'
        WHEN 'colorado' THEN 'CO'
        WHEN 'co' THEN 'CO'
        WHEN 'florida' THEN 'FL'
        WHEN 'fl' THEN 'FL'
        WHEN 'georgia' THEN 'GA'
        WHEN 'ga' THEN 'GA'
        WHEN 'illinois' THEN 'IL'
        WHEN 'il' THEN 'IL'
        WHEN 'new york' THEN 'NY'
        WHEN 'ny' THEN 'NY'
        WHEN 'texas' THEN 'TX'
        WHEN 'tx' THEN 'TX'
        WHEN 'washington' THEN 'WA'
        WHEN 'wa' THEN 'WA'
        ELSE UPPER(TRIM(REPLACE(shipping_state, CHAR(13), '')))
    END AS shipping_state
INTO clean_orders
FROM order_dedup
WHERE rn = 1;
GO

/*--------------------------------------------------------------
  4. Clean Order Items
--------------------------------------------------------------*/

DROP TABLE IF EXISTS clean_order_items;
GO

WITH item_dedup AS
(SELECT *, ROW_NUMBER() OVER (PARTITION BY order_item_id, order_id, product_id,
                quantity, unit_price, discount_pct
            ORDER BY order_item_id) AS rn
    FROM raw_order_items
)
SELECT TRIM(order_item_id) AS order_item_id, TRIM(order_id) AS order_id,
    TRIM(product_id) AS product_id,

    CASE WHEN TRY_CONVERT(INT, TRIM(quantity)) > 0
        THEN TRY_CONVERT(INT, TRIM(quantity))
        ELSE NULL
    END AS quantity,

    CASE WHEN TRY_CONVERT(DECIMAL(10,2), NULLIF(TRIM(unit_price), '')) >= 0
        THEN TRY_CONVERT(DECIMAL(10,2), NULLIF(TRIM(unit_price), ''))
        ELSE NULL
    END AS unit_price,

    CASE WHEN TRY_CONVERT(DECIMAL(6,4), NULLIF(TRIM(REPLACE(discount_pct, CHAR(13), '')), ''))
        BETWEEN 0 AND 1
        THEN TRY_CONVERT(DECIMAL(6,4), NULLIF(TRIM(REPLACE(discount_pct, CHAR(13), '')), ''))
        ELSE NULL
    END AS discount_pct,

    CASE WHEN TRY_CONVERT(INT, TRIM(quantity)) > 0
        THEN 'VALID' ELSE 'INVALID'
    END AS quantity_flag,

    CASE
        WHEN NULLIF(TRIM(unit_price), '') IS NULL THEN 'MISSING'
        WHEN TRY_CONVERT(DECIMAL(10,2), TRIM(unit_price)) >= 0 THEN 'VALID'
        ELSE 'INVALID'
    END AS unit_price_flag,

    CASE
        WHEN NULLIF(TRIM(REPLACE(discount_pct, CHAR(13), '')), '') IS NULL
            THEN 'MISSING'
        WHEN TRY_CONVERT(DECIMAL(6,4), TRIM(REPLACE(discount_pct, CHAR(13), '')))
            BETWEEN 0 AND 1 THEN 'VALID'
        ELSE 'INVALID'
    END AS discount_flag

INTO clean_order_items
FROM item_dedup
WHERE rn = 1;
GO

/*--------------------------------------------------------------
  5. Create Canonical Customer ID Mapping
--------------------------------------------------------------*/

DROP TABLE IF EXISTS customer_id_map;
GO

SELECT customer_id AS source_customer_id,
    CASE WHEN NULLIF(TRIM(email), '') IS NULL THEN customer_id
         ELSE MIN(customer_id) OVER (PARTITION BY LOWER(TRIM(email)))
    END AS canonical_customer_id
INTO customer_id_map
FROM clean_customers;
GO

/*--------------------------------------------------------------
  6. Add Canonical Customer ID to Orders
--------------------------------------------------------------*/

ALTER TABLE clean_orders
ADD canonical_customer_id VARCHAR(20);
GO

UPDATE o
SET canonical_customer_id = m.canonical_customer_id
FROM clean_orders o
LEFT JOIN customer_id_map m
    ON o.customer_id = m.source_customer_id;
/*
(792 rows affected)
(150 rows affected)
(3440 rows affected)
(8181 rows affected)
(792 rows affected)
(3440 rows affected)
Completion time: 2026-10-13T18:05:14.7318418-05:00
*/
GO
