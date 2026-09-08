/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 01_create_database_raw_tables.sql
  Purpose: Create the SQL Server database and raw staging tables
==============================================================*/

CREATE DATABASE CustomerOrdersAnalytics;
GO

USE CustomerOrdersAnalytics;
GO

CREATE TABLE raw_customers (
    customer_id	VARCHAR(20),
    first_name	VARCHAR(100),
    last_name 	VARCHAR(100),
    email     	VARCHAR(200),
    phone     	VARCHAR(50),
    city	      VARCHAR(100),
    state     	VARCHAR(100),
    signup_date	VARCHAR(50)
);
CREATE TABLE raw_products (
    product_id   VARCHAR(20),
    product_name VARCHAR(200),
    category     VARCHAR(100),
    list_price   VARCHAR(50),
    cost         VARCHAR(50),
    active_flag  VARCHAR(20)
);
CREATE TABLE raw_orders (
    order_id      VARCHAR(20),
    customer_id   VARCHAR(20),
    order_date    VARCHAR(50),
    ship_date     VARCHAR(50),
    order_status  VARCHAR(50),
    payment_method VARCHAR(50),
    shipping_state VARCHAR(100)
);
CREATE TABLE raw_order_items (
    order_item_id VARCHAR(20),
    order_id      VARCHAR(20),
    product_id    VARCHAR(20),
    quantity      VARCHAR(50),
    unit_price    VARCHAR(50),
    discount_pct  VARCHAR(50)
);
GO  
