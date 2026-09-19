/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 03_data_profiling.sql
  Purpose: Profile duplicates, missing values, invalid values,
           text inconsistencies, and relationship issues
==============================================================*/

USE CustomerOrdersAnalytics;
GO

/*--------------------------------------------------------------
  1. Row Counts
--------------------------------------------------------------*/

SELECT COUNT(*) AS customer_count FROM raw_customers;
-- 800
SELECT COUNT(*) AS product_count FROM raw_products;
-- 150
SELECT COUNT(*) AS order_count FROM raw_orders;
-- 3500
SELECT COUNT(*) AS order_item_count FROM raw_order_items;
-- 8200


/*--------------------------------------------------------------
  2. Exact Duplicate IDs
--------------------------------------------------------------*/

SELECT customer_id, COUNT(*) AS duplicate_count
FROM raw_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
-- 8 rows, 2 duplicate each  

SELECT product_id, COUNT(*) AS duplicate_count
FROM raw_products
GROUP BY product_id
HAVING COUNT(*) > 1;                
-- 0 rows

SELECT order_id, COUNT(*) AS duplicate_count
FROM raw_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
-- 60 rows, 2 duplicate each

SELECT order_item_id, COUNT(*) AS duplicate_count
FROM raw_order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1;
-- 19 rows, 2 duplicate each

/*--------------------------------------------------------------
  3. Missing Values
--------------------------------------------------------------*/
-- Customers
SELECT SUM(CASE WHEN NULLIF(TRIM(customer_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN NULLIF(TRIM(first_name), '') IS NULL THEN 1 ELSE 0 END) AS missing_first_name,
    SUM(CASE WHEN NULLIF(TRIM(last_name), '') IS NULL THEN 1 ELSE 0 END) AS missing_last_name,
    SUM(CASE WHEN NULLIF(TRIM(email), '') IS NULL THEN 1 ELSE 0 END) AS missing_email,
    SUM(CASE WHEN NULLIF(TRIM(phone), '') IS NULL THEN 1 ELSE 0 END) AS missing_phone,
    SUM(CASE WHEN NULLIF(TRIM(city), '') IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN NULLIF(TRIM(state), '') IS NULL THEN 1 ELSE 0 END) AS missing_state,
    SUM(CASE WHEN NULLIF(TRIM(REPLACE(signup_date, CHAR(13), '')), '') IS NULL THEN 1 ELSE 0 END) AS missing_signup_date      
FROM raw_customers;
-- missing_email = 16, missing_phone = 31, missing_signup_date = 16

-- Products
SELECT SUM(CASE WHEN NULLIF(TRIM(product_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN NULLIF(TRIM(product_name), '') IS NULL THEN 1 ELSE 0 END) AS missing_product_name,
    SUM(CASE WHEN NULLIF(TRIM(category), '') IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN NULLIF(TRIM(list_price), '') IS NULL THEN 1 ELSE 0 END) AS missing_list_price,
    SUM(CASE WHEN NULLIF(TRIM(cost), '') IS NULL THEN 1 ELSE 0 END) AS missing_cost,
    SUM(CASE WHEN NULLIF(TRIM(REPLACE(active_flag, CHAR(13), '')), '') IS NULL THEN 1 ELSE 0 END) AS missing_active_flag
FROM raw_products;
-- -- missing_category=5, missing_list_price=5

-- Orders 
SELECT SUM(CASE WHEN NULLIF(TRIM(order_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN NULLIF(TRIM(customer_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN NULLIF(TRIM(order_date), '') IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN NULLIF(TRIM(ship_date), '') IS NULL THEN 1 ELSE 0 END) AS missing_ship_date,
    SUM(CASE WHEN NULLIF(TRIM(order_status), '') IS NULL THEN 1 ELSE 0 END) AS missing_order_status,
    SUM(CASE WHEN NULLIF(TRIM(payment_method), '') IS NULL THEN 1 ELSE 0 END) AS missing_payment_method,
    SUM(CASE WHEN NULLIF(TRIM(REPLACE(shipping_state, CHAR(13), '')), '') IS NULL THEN 1 ELSE 0 END) AS missing_shipping_state
FROM raw_orders;
-- missing_order_date = 25, missing_ship_date = 694 

-- Order Items
SELECT SUM(CASE WHEN NULLIF(TRIM(order_item_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_order_item_id,
    SUM(CASE WHEN NULLIF(TRIM(order_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN NULLIF(TRIM(product_id), '') IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN NULLIF(TRIM(quantity), '') IS NULL THEN 1 ELSE 0 END) AS missing_quantity,
    SUM(CASE WHEN NULLIF(TRIM(unit_price), '') IS NULL THEN 1 ELSE 0 END) AS missing_unit_price,
    SUM(CASE WHEN NULLIF(TRIM(REPLACE(discount_pct, CHAR(13), '')), '') IS NULL THEN 1 ELSE 0 END) AS missing_discount
FROM raw_order_items;
-- missing_unit_price = 143, missing_discount = 82          

-- Investigating 694 missing ship dates for Processing or Cancellation 
SELECT order_status, COUNT(*) AS missing_ship_date_count
FROM raw_orders
WHERE NULLIF(TRIM(ship_date), '') IS NULL
GROUP BY order_status
ORDER BY missing_ship_date_count DESC;
order_status	missing_ship_date_count
-- Processing = 393, Cancelled = 301
-- totaling = 694 ==> NULL ship dates are valid

/*--------------------------------------------------------------
  4. Invalid Numeric Values
--------------------------------------------------------------*/
-- Order Items: quantity, unit price, list price
SELECT SUM(CASE WHEN NULLIF(TRIM(quantity), '') IS NOT NULL
     	  AND (TRY_CONVERT(INT, quantity) IS NULL
        OR TRY_CONVERT(INT, quantity) <= 0)
        THEN 1 ELSE 0 
	END) AS invalid_quantity,

    SUM(CASE WHEN NULLIF(TRIM(unit_price), '') IS NOT NULL
        AND (TRY_CONVERT(DECIMAL(10,2), TRIM(unit_price)) IS NULL
        OR TRY_CONVERT(DECIMAL(10,2), TRIM(unit_price)) < 0)
        THEN 1 ELSE 0 
	END) AS invalid_unit_price,

    SUM(CASE WHEN NULLIF(TRIM(REPLACE(discount_pct, CHAR(13), '')), '') IS NOT NULL
        AND (TRY_CONVERT(DECIMAL(6,4), TRIM(REPLACE(discount_pct, CHAR(13), ''))) IS NULL
            OR TRY_CONVERT(DECIMAL(6,4), TRIM(REPLACE(discount_pct, CHAR(13), ''))) NOT BETWEEN 0 AND 1)
        THEN 1 ELSE 0 
	END) AS invalid_discount
FROM raw_order_items;
-- invalid_quantity=134, invalid_unit_price=60, invalid_discount=205

-- Products: product price and cost
SELECT
    SUM(CASE
        WHEN NULLIF(TRIM(list_price), '') IS NOT NULL
         AND (TRY_CONVERT(DECIMAL(10,2), list_price) IS NULL
             OR TRY_CONVERT(DECIMAL(10,2), list_price) < 0
         )
        THEN 1 ELSE 0
    END) AS invalid_list_price,

    SUM(CASE
        WHEN NULLIF(TRIM(cost), '') IS NOT NULL
         AND (TRY_CONVERT(DECIMAL(10,2), cost) IS NULL
             OR TRY_CONVERT(DECIMAL(10,2), cost) < 0
         )
        THEN 1 ELSE 0
    END) AS invalid_cost
FROM raw_products;        
-- 0, 0
/*--------------------------------------------------------------
  5. Invalid Dates
--------------------------------------------------------------*/
-- Orders; order date
SELECT order_date, COUNT(*) AS invalid_count
FROM raw_orders
WHERE NULLIF(TRIM(order_date), '') IS NOT NULL
  AND TRY_CONVERT(DATE, TRIM(order_date)) IS NULL
GROUP BY order_date
ORDER BY invalid_count;  
-- order_date = 2025-13-40	   invalid_count = 24

-- Orders: ship date
SELECT ship_date, COUNT(*) AS invalid_count
FROM raw_orders
WHERE NULLIF(TRIM(ship_date), '') IS NOT NULL
  AND TRY_CONVERT(DATE, TRIM(ship_date)) IS NULL
GROUP BY ship_date
ORDER BY invalid_count; 
-- 0 rows

-- ship date earlier than its order date? 
SELECT order_date, ship_date, COUNT(*) AS invalid_count
FROM raw_orders
WHERE TRY_CONVERT(DATE, TRIM(order_date)) IS NOT NULL
  AND TRY_CONVERT(DATE, TRIM(ship_date)) IS NOT NULL
  AND TRY_CONVERT(DATE, TRIM(ship_date)) <
      TRY_CONVERT(DATE, TRIM(order_date))
GROUP BY order_date, ship_date
ORDER BY order_date;           
-- 0 rows
/*--------------------------------------------------------------
  6. Text Variations
--------------------------------------------------------------*/

SELECT state, COUNT(*) AS row_count
FROM raw_customers
GROUP BY state
ORDER BY state;
-- 18 rows; ex: Texas: Tx = 150 and texas = 22. No standardized TX value.

SELECT category, COUNT(*) AS row_count
FROM raw_products
GROUP BY category
ORDER BY category;
-- 14 rows --> category needs standardization 

SELECT TRIM(REPLACE(active_flag, CHAR(13), '')) AS active_flag,
    COUNT(*) AS row_count
FROM raw_products
GROUP BY TRIM(REPLACE(active_flag, CHAR(13), ''))
ORDER BY active_flag;
-- 4 rows --> active flag needs standardization

SELECT TRIM(REPLACE(shipping_state, CHAR(13), '')) AS shipping_state,
    COUNT(*) AS row_count
FROM raw_orders
GROUP BY TRIM(REPLACE(shipping_state, CHAR(13), ''))
ORDER BY shipping_state;
-- 18 rows; states needs standardization

/*--------------------------------------------------------------
  7. Duplicate Customer Identities
--------------------------------------------------------------*/    ==> CHECK
-- different customer IDs share the same email address.
SELECT LOWER(TRIM(email)) AS email, COUNT(DISTINCT customer_id) AS customer_count
FROM raw_customers
WHERE NULLIF(TRIM(email), '') IS NOT NULL
GROUP BY LOWER(TRIM(email))
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY email;
-- 17 rows, each appear twice

-- Details
SELECT customer_id, first_name, last_name, email,
       phone, city, state, signup_date
FROM raw_customers
WHERE LOWER(TRIM(email)) IN (
    SELECT LOWER(TRIM(email))
    FROM raw_customers
    WHERE NULLIF(TRIM(email), '') IS NOT NULL
    GROUP BY LOWER(TRIM(email))
    HAVING COUNT(DISTINCT customer_id) > 1 )
ORDER BY email, customer_id;
 
-- different customer IDs share the same phone number.
SELECT TRIM(phone) AS phone, COUNT(DISTINCT customer_id) AS customer_count
FROM raw_customers
WHERE NULLIF(TRIM(phone), '') IS NOT NULL
GROUP BY TRIM(phone)
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY customer_count DESC, phone;
-- 15 rows, each appear twice
/*--------------------------------------------------------------
  8. Referential Integrity
--------------------------------------------------------------*/

SELECT 'order_items-orphan_order_id', COUNT(*) AS row_count         
FROM raw_order_items oi
LEFT JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items-orphan_product_id', COUNT(*) 
FROM raw_order_items oi
LEFT JOIN raw_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'orders-orphan_customer_id', COUNT(*)
FROM raw_orders o
LEFT JOIN raw_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- order_items-orphan_order_id = 25, order_items-orphan_product_id = 15, 
-- orders-orphan_customer_id = 31

-- Details
SELECT oi.order_id, COUNT(*) AS orphan_order_items          
FROM raw_order_items oi
LEFT JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
GROUP BY oi.order_id
ORDER BY oi.order_id;

SELECT oi.product_id, COUNT(*) AS orphan_product_items
FROM raw_order_items oi
LEFT JOIN raw_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY oi.product_id
ORDER BY oi.product_id;    

SELECT o.customer_id, COUNT(*) AS orphan_customer_orders
FROM raw_orders o
LEFT JOIN raw_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
GROUP BY o.customer_id
ORDER BY o.customer_id;

/*--------------------------------------------------------------
  9. Business Rule Check
--------------------------------------------------------------*/

SELECT COUNT(*) AS orders_before_signup
FROM raw_orders o
JOIN raw_customers c
    ON o.customer_id = c.customer_id
WHERE TRY_CONVERT(DATE, o.order_date) IS NOT NULL
  AND TRY_CONVERT(DATE,
      TRIM(REPLACE(c.signup_date, CHAR(13), ''))) IS NOT NULL
  AND TRY_CONVERT(DATE, o.order_date) <
      TRY_CONVERT(DATE,
      TRIM(REPLACE(c.signup_date, CHAR(13), '')));
-- 1102


