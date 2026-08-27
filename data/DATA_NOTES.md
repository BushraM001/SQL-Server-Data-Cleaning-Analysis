# Customer Orders Data Quality & SQL Analysis

## User Story

As a data analyst, I want to clean, validate, and analyze customer order data so that the business can rely on accurate customer, product, sales, and order information for reporting and decision-making.

## Project Requirements

The SQL analysis should:

- Identify and remove duplicate records
- Handle missing and invalid values
- Standardize states and product categories
- Validate dates, prices, quantities, and discounts
- Identify orphan records and broken relationships
- Create clean tables for analysis
- Analyze sales, customers, products, and order trends
- Use joins, CTEs, window functions, aggregations, and views

## Data Generation

The dataset is fully synthetic and was generated specifically for this portfolio project.

- **Customers:** 800 records
- **Products:** 150 records
- **Orders:** 3,500 records
- **Order Items:** 8,200 records

Intentional data-quality issues were added, including duplicates, NULL values, inconsistent formats, invalid dates, incorrect prices and discounts, and orphan records.

The raw CSV files should remain unchanged. All cleaning and transformation will be performed in SQL Server.
