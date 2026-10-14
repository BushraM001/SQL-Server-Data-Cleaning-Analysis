/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 06_data_validation.sql
  Purpose: Validate cleaned data, relationships, and sales KPIs
==============================================================*/

USE CustomerOrdersAnalytics;
GO

/* 1. Raw vs Clean Row Counts */

SELECT 'Customers' AS table_name,
    (SELECT COUNT(*) FROM raw_customers) AS raw_rows,
    (SELECT COUNT(*) FROM clean_customers) AS clean_rows
UNION ALL
SELECT 'Products',
    (SELECT COUNT(*) FROM raw_products),
    (SELECT COUNT(*) FROM clean_products)
UNION ALL
SELECT 'Orders',
    (SELECT COUNT(*) FROM raw_orders),
    (SELECT COUNT(*) FROM clean_orders)
UNION ALL
SELECT 'Order Items',
    (SELECT COUNT(*) FROM raw_order_items),
    (SELECT COUNT(*) FROM clean_order_items);


/* 2. Duplicate ID Validation */

SELECT customer_id, COUNT(*) AS duplicate_count
FROM clean_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS duplicate_count
FROM clean_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_item_id, COUNT(*) AS duplicate_count
FROM clean_order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1;


/* 3. Invalid Value Flags */

SELECT quantity_flag, COUNT(*) AS row_count
FROM clean_order_items
GROUP BY quantity_flag;

SELECT unit_price_flag, COUNT(*) AS row_count
FROM clean_order_items
GROUP BY unit_price_flag;

SELECT discount_flag, COUNT(*) AS row_count
FROM clean_order_items
GROUP BY discount_flag;


/* 4. Relationship Validation */

SELECT order_relationship_flag, product_relationship_flag,
    COUNT(*) AS row_count
FROM vw_order_items_quality
GROUP BY order_relationship_flag, product_relationship_flag
ORDER BY order_relationship_flag, product_relationship_flag;

SELECT COUNT(*) AS unmapped_orders
FROM clean_orders
WHERE canonical_customer_id IS NULL;


/* 5. Customer Mapping Validation */

SELECT COUNT(*) AS source_customers,
    COUNT(DISTINCT canonical_customer_id) AS canonical_customers,
    SUM(CASE WHEN source_customer_id <> canonical_customer_id
        THEN 1 ELSE 0 END) AS remapped_customers
FROM customer_id_map;


/* 6. Analysis-Ready Row Counts */

SELECT COUNT(*) AS valid_order_items
FROM vw_order_items_analysis;

SELECT COUNT(*) AS sales_analysis_rows
FROM vw_sales_analysis;


/* 7. Recognized Sales KPI Validation */

SELECT COUNT(DISTINCT CASE
        WHEN order_status IN ('Completed', 'Shipped')
        THEN order_id END) AS recognized_orders,
    CAST(SUM(recognized_sales) AS DECIMAL(18,2)) AS recognized_sales,
    CAST(SUM(recognized_profit) AS DECIMAL(18,2)) AS recognized_profit,
    CAST(SUM(recognized_profit) * 100.0 /
        NULLIF(SUM(recognized_sales), 0) AS DECIMAL(10,2)) AS profit_margin_pct
FROM vw_sales_analysis;


/* 8. Missing Order Date Reconciliation */

SELECT
    CAST(SUM(CASE WHEN order_date IS NOT NULL
        THEN recognized_sales ELSE 0 END)
        AS DECIMAL(18,2)) AS dated_sales,
    CAST(SUM(CASE WHEN order_date IS NULL
        THEN recognized_sales ELSE 0 END)
        AS DECIMAL(18,2)) AS undated_sales,
    CAST(SUM(recognized_sales)
        AS DECIMAL(18,2)) AS total_recognized_sales
FROM vw_sales_analysis;
GO
