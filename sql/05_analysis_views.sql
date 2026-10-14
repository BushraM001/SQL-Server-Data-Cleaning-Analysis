--This script creates three views:
--1. vw_order_items_quality — flags orphan relationships.
--2. vw_customers_analysis — keeps one record per canonical customer.
--3. vw_order_items_analysis — calculates valid line-item sales.
--4. vw_sales_analysis — combines sales, customers, and products with recognized sales and profit.
--------------------------------------
/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 05_analysis_views.sql
  Purpose: Create quality and analysis-ready SQL views
==============================================================*/

USE CustomerOrdersAnalytics;
GO

/* 1. Order Item Relationship Quality */

CREATE OR ALTER VIEW vw_order_items_quality AS
SELECT oi.*,
    CASE WHEN o.order_id IS NULL THEN 'ORPHAN_ORDER'
        ELSE 'VALID' END AS order_relationship_flag,
    CASE WHEN p.product_id IS NULL THEN 'ORPHAN_PRODUCT'
        ELSE 'VALID' END AS product_relationship_flag
FROM clean_order_items oi
LEFT JOIN clean_orders o ON oi.order_id = o.order_id
LEFT JOIN clean_products p ON oi.product_id = p.product_id;
GO

/* 2. Canonical Customers */

CREATE OR ALTER VIEW vw_customers_analysis AS
SELECT m.canonical_customer_id AS customer_id,
    c.first_name, c.last_name, c.email, c.phone,
    c.city, c.state, c.signup_date
FROM clean_customers c
JOIN customer_id_map m
    ON c.customer_id = m.source_customer_id
WHERE m.source_customer_id = m.canonical_customer_id;
GO

/* 3. Valid Order Items */

CREATE OR ALTER VIEW vw_order_items_analysis AS
SELECT oi.order_item_id, oi.order_id, oi.product_id,
    oi.quantity, oi.unit_price, oi.discount_pct,
    CAST(oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        AS DECIMAL(12,2)) AS net_sales
FROM vw_order_items_quality oi
WHERE oi.order_relationship_flag = 'VALID'
  AND oi.product_relationship_flag = 'VALID'
  AND oi.quantity_flag = 'VALID'
  AND oi.unit_price_flag = 'VALID'
  AND oi.discount_flag = 'VALID';
GO

/* 4. Sales Analysis */

CREATE OR ALTER VIEW vw_sales_analysis AS
SELECT oi.order_item_id, oi.order_id, o.order_date,
    o.ship_date, o.order_status, o.payment_method, o.shipping_state,
    o.canonical_customer_id AS customer_id,
    c.first_name, c.last_name, c.state AS customer_state,
    oi.product_id, p.product_name, p.category,
    oi.quantity, oi.unit_price, oi.discount_pct, oi.net_sales, p.cost,

    CAST(oi.quantity * p.cost AS DECIMAL(12,2)) AS total_cost,

    CAST(oi.net_sales - (oi.quantity * p.cost)
        AS DECIMAL(12,2)) AS profit,

    CAST(CASE WHEN o.order_status IN ('Completed', 'Shipped')
        THEN oi.net_sales ELSE 0 END
        AS DECIMAL(12,2)) AS recognized_sales,

    CAST(CASE WHEN o.order_status IN ('Completed', 'Shipped')
        THEN oi.net_sales - (oi.quantity * p.cost)
        ELSE 0 END AS DECIMAL(12,2)) AS recognized_profit

FROM vw_order_items_analysis oi
JOIN clean_orders o ON oi.order_id = o.order_id
JOIN clean_products p ON oi.product_id = p.product_id
LEFT JOIN vw_customers_analysis c
    ON o.canonical_customer_id = c.customer_id;
GO
