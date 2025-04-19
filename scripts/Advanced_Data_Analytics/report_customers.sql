/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO
CREATE VIEW gold.report_customers AS


/*
Step 1: Create an BASE QUERY CTE
	Start with the FACT tables, and left join with dimension tables. 
	Filter the join results and perform any necessay transformation
*/

WITH base_query AS(
	SELECT
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) AS age
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
	WHERE order_date IS NOT NULL
)

/*
Step 2: Create an Aggregation CTE
Aggregate customer_level metrics
*/
, customer_aggregation AS(
	SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY customer_key, customer_number, customer_name, age
)

/*
Step 3: Generate Final Result with final transformation
*/

SELECT
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 THEN 'Under 20'
	 WHEN age BETWEEN 20 AND 29 THEN '20-29'
	 WHEN age BETWEEN 30 AND 39 THEN '30-39'
	 WHEN age BETWEEN 40 AND 49 THEN '40-49'
	 ELSE 'Above 50'
END AS age_group,
CASE WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
		 WHEN total_sales <= 5000 AND lifespan >= 12 THEN 'REGULAR'
		 ELSE 'NEW'
END AS customer_segment,
total_orders,
total_sales,
total_products,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency,
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales/total_orders 
END AS avg_order_value,
lifespan,
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales/lifespan 
END AS avg_monthly_spend

FROM customer_aggregation;
