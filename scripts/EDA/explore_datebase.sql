/*
=============================================================
Exploratory Data Analysis (EDA)
=============================================================
This document outlines the systematic approach to conducting exploratory data analysis on our dataset. 
EDA is a critical preliminary step in data analysis that helps us understand the structure, patterns, 
and characteristics of the data before applying more advanced analytical techniques.

Purpose:
- Understand the fundamental properties of the dataset
- Identify patterns, anomalies, and insights
- Assess data quality and completeness
- Guide further analysis and modeling decisions

Techniques Applied:
1. Basic Queries
2. Data Profiling
3. Simple Aggregation
4. Subqueries

Measure vs. Dimension Classification
  - **Dimensions**: Categorical or discrete variables used for grouping, filtering, or segmenting data (e.g., region, product category, date).
  - **Measures**: Numeric variables that can be meaningfully aggregated through operations like sum, average, or count (e.g., sales, quantity, profit).
When analyzing variables, we apply the following classification logic:

```
Is Data Type == Number?
├── No → Dimension
└── Yes → Does it make sense to aggregate it?
    ├── Yes → Measure
    └── No → Dimension
```

*/

-- **Step 1: Database Exploration**
-- Explore All Objects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Explore All Columns in the Database;
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';

-- **Step 2: Dimensions Exploration**
-- Identify the unique values (or categories) in each dimension.
-- Recognise how data might be grouped or segmented which is useful for later analysis
-- DISTINCT [DIMENSION] e.g., DISTINCT[country]

-- Explore All Countries our customers come from
SELECT DISTINCT country FROM gold.dim_customers;

-- Explore All Categories "The Major Division"
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3;

-- **Step 3: Date Exploration**
-- Identify the earliest and latest dates (boundaries). MIN/MAX [Date Dimension]. e.g., MIN(order_date)
-- Understand the scope of data and the timespan.

-- Find the date of the first and last order
-- How many years of sales are available
SELECT 
MIN(order_date) AS first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales;

-- Find the youngest and the oldest customer
SELECT
MIN(birthdate) AS oldest_birthdate,
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year, Max(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers


-- **Step 4: Measures Exploration**
-- Calculate the key metric of the business (Big Numbers)
-- Highest Level of Aggregation | Lowest Level of Details
-- SQL Aggregation Function (Measure)

--Find the total sales
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

--Find how many items are sold
SELECT SUM(quantity) AS total_items
FROM gold.fact_sales;

--Find the avearge selling price
SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

--Find the total number of orders
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

--Find the total number of customers
SELECT COUNT(customer_number) AS total_customers
FROM gold.dim_customers;

--Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales;

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Product' AS measure_name, SUM(product_key) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Average Price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Customers' AS measure_name, COUNT(customer_number) AS measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Total Customers Placing Order' AS measure_name, COUNT(DISTINCT customer_key) AS measure_value FROM gold.fact_sales

--**Step 5: Magnitude**
-- Compare the measure values by categories
-- It helps us understand the importance of different categories
-- Aggregate [Measure] By [Dimension] e.g. Total Sales By Country; Total Quantity By Category.


-- Find total customer by country
SELECT country, COUNT(*) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Find total customers by gender
SELECT gender, COUNT(*) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Find total products by category
SELECT category, COUNT(*) as total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- What is the average costs in each category?
SELECT category, AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- What is the total revenue generated for each category
-- Tip: "I usually start with the Fact then Left Join the dimensions to it"
SELECT category, SUM(sales_amount) AS total_revenue
FROM gold.fact_sales  a
LEFT JOIN gold.dim_products b
ON a.product_key = b.product_key
GROUP BY category
ORDER BY total_revenue DESC;


-- Find total revenue is generaged by each custoer
SELECT customer_id, first_name, last_name, SUM(sales_amount) AS total_revenue
FROM gold.fact_sales  a
LEFT JOIN gold.dim_customers b
ON a.customer_key = b.customer_key
GROUP BY customer_id, first_name, last_name
ORDER BY total_revenue DESC;

-- What is the distribution of sold items across countries?
SELECT country, sum(quantity) as total_quantity
FROM gold.fact_sales  a
LEFT JOIN gold.dim_customers b
ON a.customer_key = b.customer_key
GROUP BY country
ORDER BY total_quantity DESC;

-- **Step 6: Ranking Analysis**
 -- Order the values of dimensions by measure
 -- Top N performers | Bottom N performers
 -- Rank [Dimension] By Aggregation of Measure
 -- e.g. Rank Countries by Total Sales, Top 5 Products by Quantity
 -- Top, Rank(), DenseRank(), RowNumber()

 -- Which 5 products generate the highest revenue?
SELECT TOP 5
product_number, product_name, SUM(sales_amount) AS total_revenue
FROM gold.fact_sales  a
LEFT JOIN gold.dim_products b
ON a.product_key = b.product_key
GROUP BY product_number, product_name
ORDER BY total_revenue DESC

-- Approach 2: Window Function
SELECT *
FROM (
	SELECT 
	product_number, product_name, SUM(sales_amount) AS total_revenue,
	ROW_NUMBER() OVER(ORDER BY SUM(sales_amount) DESC) AS rank_products
	FROM gold.fact_sales  a
	LEFT JOIN gold.dim_products b
	ON a.product_key = b.product_key
	GROUP BY product_number, product_name
)t
WHERE rank_products < = 5;

 -- What are the 5 worst performing products in terms of sales?
 SELECT TOP 5
product_number, product_name, SUM(sales_amount) AS total_revenue
FROM gold.fact_sales  a
LEFT JOIN gold.dim_products b
ON a.product_key = b.product_key
GROUP BY product_number, product_name
ORDER BY total_revenue;
