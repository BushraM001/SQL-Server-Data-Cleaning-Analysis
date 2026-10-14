--This final SQL script brings together the business analyses we already completed, using recognized sales (Completed and Shipped orders).
/*==============================================================
  Project: Customer Orders Data Cleaning & Analysis
  File: 07_business_analysis.sql
  Purpose: Analyze sales, profitability, customers, products,
           discounts, and year-over-year performance
==============================================================*/

USE CustomerOrdersAnalytics;
GO

/* 1. Key Performance Indicators */

SELECT
    COUNT(DISTINCT CASE WHEN order_status IN ('Completed', 'Shipped')
        THEN order_id END) AS recognized_orders,
    CAST(SUM(recognized_sales) AS DECIMAL(18,2)) AS recognized_sales,
    CAST(SUM(recognized_profit) AS DECIMAL(18,2)) AS recognized_profit,
    CAST(SUM(recognized_profit) * 100.0 /
        NULLIF(SUM(recognized_sales), 0) AS DECIMAL(10,2)) AS profit_margin_pct,
    CAST(SUM(recognized_sales) /
        NULLIF(COUNT(DISTINCT CASE WHEN order_status IN ('Completed', 'Shipped')
            THEN order_id END), 0) AS DECIMAL(18,2)) AS avg_order_value
FROM vw_sales_analysis;


/* 2. Monthly Recognized Sales */

SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month,
    CAST(SUM(recognized_sales) AS DECIMAL(18,2)) AS recognized_sales,
    CAST(SUM(recognized_profit) AS DECIMAL(18,2)) AS recognized_profit
FROM vw_sales_analysis
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


/* 3. Running Monthly Sales Total */

WITH monthly_sales AS
(
    SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month,
        SUM(recognized_sales) AS monthly_sales
    FROM vw_sales_analysis
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT order_year, order_month,
    CAST(monthly_sales AS DECIMAL(18,2)) AS monthly_sales,
    CAST(SUM(monthly_sales) OVER (
        ORDER BY order_year, order_month ROWS UNBOUNDED PRECEDING
    ) AS DECIMAL(18,2)) AS running_total
FROM monthly_sales
ORDER BY order_year, order_month;


/* 4. Year-over-Year Growth: January–July */

WITH ytd_sales AS
(
    SELECT YEAR(order_date) AS order_year,
        SUM(recognized_sales) AS ytd_sales
    FROM vw_sales_analysis
    WHERE order_date IS NOT NULL
      AND MONTH(order_date) <= 7
    GROUP BY YEAR(order_date)
),
yoy_ytd AS
(
    SELECT order_year, ytd_sales,
        LAG(ytd_sales) OVER (ORDER BY order_year) AS previous_year_ytd
    FROM ytd_sales
)
SELECT order_year,
    CAST(ytd_sales AS DECIMAL(18,2)) AS jan_jul_sales,
    CAST(previous_year_ytd AS DECIMAL(18,2)) AS previous_year_jan_jul,
    CAST((ytd_sales - previous_year_ytd) * 100.0 /
        NULLIF(previous_year_ytd, 0) AS DECIMAL(10,2)) AS yoy_growth_pct
FROM yoy_ytd
ORDER BY order_year;


/* 5. Sales and Profit by Category */

SELECT category,
    CAST(SUM(recognized_sales) AS DECIMAL(18,2)) AS recognized_sales,
    CAST(SUM(recognized_profit) AS DECIMAL(18,2)) AS recognized_profit,
    CAST(SUM(recognized_profit) * 100.0 /
        NULLIF(SUM(recognized_sales), 0) AS DECIMAL(10,2)) AS profit_margin_pct
FROM vw_sales_analysis
GROUP BY category
ORDER BY recognized_sales DESC;


/* 6. Top 10 Products */

WITH product_sales AS
(
    SELECT product_id, product_name, category,
        SUM(recognized_sales) AS recognized_sales,
        SUM(recognized_profit) AS recognized_profit
    FROM vw_sales_analysis
    GROUP BY product_id, product_name, category
),
ranked_products AS
(
    SELECT *,
        RANK() OVER (ORDER BY recognized_sales DESC) AS sales_rank
    FROM product_sales
)
SELECT sales_rank, product_id, product_name, category,
    CAST(recognized_sales AS DECIMAL(18,2)) AS recognized_sales,
    CAST(recognized_profit AS DECIMAL(18,2)) AS recognized_profit
FROM ranked_products
WHERE sales_rank <= 10
ORDER BY sales_rank;


/* 7. Top 10 Customers */

WITH customer_sales AS
(
    SELECT customer_id, first_name, last_name, customer_state,
        COUNT(DISTINCT CASE WHEN order_status IN ('Completed', 'Shipped')
            THEN order_id END) AS recognized_orders,
        SUM(recognized_sales) AS recognized_sales,
        SUM(recognized_profit) AS recognized_profit
    FROM vw_sales_analysis
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, first_name, last_name, customer_state
),
ranked_customers AS
(
    SELECT *,
        RANK() OVER (ORDER BY recognized_sales DESC) AS sales_rank
    FROM customer_sales
)
SELECT sales_rank, customer_id, first_name, last_name,
    customer_state, recognized_orders,
    CAST(recognized_sales AS DECIMAL(18,2)) AS recognized_sales,
    CAST(recognized_profit AS DECIMAL(18,2)) AS recognized_profit
FROM ranked_customers
WHERE sales_rank <= 10
ORDER BY sales_rank;


/* 8. Sales by Shipping State */

SELECT shipping_state,
    COUNT(DISTINCT CASE WHEN order_status IN ('Completed', 'Shipped')
        THEN order_id END) AS recognized_orders,
    CAST(SUM(recognized_sales) AS DECIMAL(18,2)) AS recognized_sales,
    CAST(SUM(recognized_profit) AS DECIMAL(18,2)) AS recognized_profit,
    CAST(SUM(recognized_profit) * 100.0 /
        NULLIF(SUM(recognized_sales), 0) AS DECIMAL(10,2)) AS profit_margin_pct
FROM vw_sales_analysis
GROUP BY shipping_state
ORDER BY recognized_sales DESC;


/* 9. Order Status Analysis */

SELECT order_status,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS sales_lines,
    CAST(SUM(net_sales) AS DECIMAL(18,2)) AS total_order_value,
    CAST(SUM(profit) AS DECIMAL(18,2)) AS potential_profit
FROM vw_sales_analysis
GROUP BY order_status
ORDER BY total_order_value DESC;


/* 10. Discount Impact */

WITH discount_analysis AS
(
    SELECT
        CASE
            WHEN discount_pct = 0 THEN 'No Discount'
            WHEN discount_pct <= 0.10 THEN '1-10%'
            WHEN discount_pct <= 0.20 THEN '11-20%'
            ELSE 'Over 20%'
        END AS discount_band,
        recognized_sales, recognized_profit
    FROM vw_sales_analysis
    WHERE order_status IN ('Completed', 'Shipped')
)
SELECT discount_band, COUNT(*) AS sales_lines,
    CAST(SUM(recognized_sales) AS DECIMAL(18,2)) AS recognized_sales,
    CAST(SUM(recognized_profit) AS DECIMAL(18,2)) AS recognized_profit,
    CAST(SUM(recognized_profit) * 100.0 /
        NULLIF(SUM(recognized_sales), 0) AS DECIMAL(10,2)) AS profit_margin_pct
FROM discount_analysis
GROUP BY discount_band
ORDER BY recognized_sales DESC;


/* 11. Repeat Customer Analysis */

WITH customer_orders AS
(
    SELECT customer_id,
        COUNT(DISTINCT order_id) AS recognized_orders,
        SUM(recognized_sales) AS recognized_sales
    FROM vw_sales_analysis
    WHERE order_status IN ('Completed', 'Shipped')
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT COUNT(*) AS purchasing_customers,
    SUM(CASE WHEN recognized_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    SUM(CASE WHEN recognized_orders = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    CAST(SUM(CASE WHEN recognized_orders > 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS repeat_customer_pct
FROM customer_orders;
GO
