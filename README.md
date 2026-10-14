# Customer Orders — SQL Server Data Cleaning & Analysis

## Project Overview

An end-to-end SQL Server project focused on cleaning, validating, transforming, and analyzing customer order data.

The project uses four related tables containing intentionally introduced data-quality issues, including duplicate records, missing key information, and referential integrity violations. Raw data is preserved, while separate clean tables and analytical views support reliable reporting.

**Tools:** SQL Server, T-SQL, SQL Server Management Studio (SSMS)

**SQL Skills:** Data Profiling, Data Cleaning, CTEs, Window Functions, Joins, Data Validation, Aggregations, and Business Analysis

## Dataset

The dataset is fully synthetic and was generated for SQL data-quality and analytical practice.

| Source Table | Raw Rows | Clean Rows |
|---|---:|---:|
| Customers | 800 | 792 |
| Products | 150 | 150 |
| Orders | 3,500 | 3,440 |
| Order Items | 8,200 | 8,181 |

After customer identity consolidation, 775 unique customer records remain in the customer analysis view.

## Data Cleaning and Quality

The project addresses:

- Exact duplicate records and duplicate customer identities
- Missing and invalid dates, quantities, prices, and discounts
- Inconsistent state abbreviations, product categories, and active flags
- Missing customer, order, and product relationships
- Customer orders dated before signup
- CSV import formatting issues

**Cleaning decisions:** Invalid numeric values are flagged rather than guessed. Missing dates remain NULL, and orphan records are preserved in the clean layer but excluded from analyses requiring valid relationships.

## Business Rules

Recognized sales include only **Completed** and **Shipped** orders. Processing, Cancelled, and Returned orders are excluded from recognized-sales KPIs.

Transactions with missing order dates remain in overall sales KPIs but are excluded from monthly and yearly trend analysis.

## Key Results

| KPI | Result |
|---|---:|
| Recognized Sales | $7,103,057.57 |
| Recognized Profit | $2,041,170.89 |
| Profit Margin | 28.74% |
| Recognized Orders | 2,213 |
| Average Order Value | $3,209.70 |
| Purchasing Customers | 732 |
| Repeat Customer Rate | 81.97% |

## Business Insights

- **Home** generated the highest recognized sales at $1.32M.
- **Outdoor** achieved the highest category profit margin at 34.77%.
- **Texas** led shipping destinations with $1.46M in recognized sales.
- **Discount impact:** Profit margins decreased from 35.27% for transactions without discounts to 15.31% for discounts above 20%.
- **Year-over-year comparison:** January–July recognized sales declined 2.50% in 2026 compared with the same period in 2025.
- **Data quality:** $101,179.46 in recognized sales had missing order dates and therefore could not be included in time-based reporting.

## Project Workflow

Raw CSV Files → SQL Server Staging Tables → Data Profiling → Data Cleaning → Data Validation → Analysis Views → Business Analysis

## SQL Scripts

| File | Description |
|---|---|
| `01_create_database_and_raw_tables.sql` | Database and raw staging tables |
| `02_load_raw_data.sql` | CSV imports |
| `03_data_profiling.sql` | Data-quality checks |
| `04_data_cleaning.sql` | Cleaning and customer ID consolidation |
| `05_analysis_views.sql` | Analytical and quality views |
| `06_data_validation.sql` | Data validation and KPI reconciliation |
| `07_business_analysis.sql` | Sales, profitability, customer, and product analysis |

SQL scripts are available in the [`sql/`](sql/) folder.

## Data Source

The four CSV files in [`data/`](data/) contain synthetic data created specifically for this project.

## Dashboard

**Power BI dashboard — planned next phase.**

The dashboard will use the SQL Server analytical layer to visualize recognized sales, profitability, customer behavior, product performance, and regional trends.
