/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 02_load_raw_data.sql
  Purpose: Load raw CSV files into SQL Server staging tables
==============================================================*/

USE CustomerOrdersAnalytics;
GO

BULK INSERT raw_customers
FROM '<YOUR_PATH>\customers.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO
BULK INSERT raw_products
FROM '<YOUR_PATH>\products.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO
BULK INSERT raw_orders
FROM '<YOUR_PATH>\orders.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO
BULK INSERT raw_order_items
FROM '<YOUR_PATH>\order_items.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

SELECT COUNT(*) AS customer_count FROM raw_customers;
SELECT COUNT(*) AS product_count FROM raw_products;
SELECT COUNT(*) AS order_count FROM raw_orders;
SELECT COUNT(*) AS order_item_count FROM raw_order_items;
GO
