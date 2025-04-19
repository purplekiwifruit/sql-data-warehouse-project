/*
===============================================================================
1. Change Over Time Analysis
- Analyze how a measure evolves over time
- Helps track trends and identify seasonality in your data
- Aggregate [Measure] By [Date Dimension]
- e.g. Total Sales By year, Average Cost By Month
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Changes Over Years
SELECT 
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

-- Changes Over Months
-- Detailed insight to discover seasonality in your data
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)

-- DATETRUNC()
-- Rounds a date or timestamp to a specified date part
SELECT 
DATETRUNC(month, order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)

-- FORMAT(): return a string
SELECT 
FORMAT(order_date, 'yyyy-MMM') AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM') 
ORDER BY FORMAT(order_date, 'yyyy-MMM') 

/*
===============================================================================
2. Cumulative Analysis
- Aggregate the data progressively over time
- Helps to understand whether our business is growing or declining
- Aggregate[Cumulative Measure] By [Date Dimension]
- e.g. Running Total Sales by Year, Moving Average of Sales By Month
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Calculate the total sales and average price per month
-- and the running total of sales and moving average_price over time
SELECT 
order_date,
total_sales,
SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date) AS running_total_sales,
avg_price,
AVG(avg_price) OVER (ORDER BY order_date) AS moving_average_price
FROM (
	SELECT
	DATETRUNC(month, order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) AS avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
)t

 /*
===============================================================================
3. Performance Analysis (Year-over-Year, Month-over-Month)
- Compare the current value to a target value
- Helps measure success and compare performance
- Current[Measure] - Target[Measure]
- e.g. Current Sales - Average Sales
- e.g. Current Year Sales - Previous Year Sales
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/ 

-- Analyze the yearly performance of products by comparing their sales
-- to both the average sales performance of the product and the previous year's sales

WITH yearly_product_sales AS(
-- retrieve the yearly performance of products
	SELECT
	p.product_name,
	YEAR(order_date) AS order_date,
	SUM(sales_amount) as total_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY p.product_name, YEAR(order_date)
)

SELECT
order_date,
product_name,
total_sales,
AVG(total_sales) OVER (PARTITION BY product_name) AS avg_sales,
total_sales - AVG(total_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN total_sales - AVG(total_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN total_sales - AVG(total_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	 ELSE 'Avg'
END AS avg_change,
LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_date) AS prev_sales,
total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_date) AS diff_prev,
CASE WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_date) > 0 THEN 'Increase'
	 WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_date) < 0 THEN 'Decrease'
	 ELSE 'No Change'
END AS avg_change
FROM yearly_product_sales
ORDER BY product_name, order_date



/*
===============================================================================
4. Part-to-Whole Analysis
  - Analyze how an individual part is performing compared to the overall
  - allowing us to understand which category has the greatest impact on the business
  - ([Measure]/Total[Measure]) * 100 By [Dimension]
  - e.g. (Sales/Total Sales) * 100 By Category
  - e.g. (Quantity/ Total Quantity) * 100 By Country
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.


SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/

-- Which categories contribute the most to overall sales?
SELECT
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)  / SUM(total_sales) OVER() ) * 100, 2), '%') AS percentatge_of_total
FROM (
SELECT
	p.category,
	SUM(s.sales_amount) total_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.category
)t
ORDER BY percentatge_of_total DESC


/*
===============================================================================
5. Data Segmentation Analysis
- Group the data based on specfic range.
- Helps understand the correlation between two measures.
- [Measure] By [Measure]
- e.g. Total Product By Sales Range
- e.g. Total Customers By Age
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

-- Segment products into cost ranges and 
-- count how many products fall into each segment
SELECT
cost_range,
COUNT(product_key) AS total_products
FROM(
	SELECT
	product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'above 1000'
	END cost_range
	FROM gold.dim_products
) t
GROUP BY cost_range
ORDER BY total_products DESC

/*
Group customers into threee segments based on their spending behavior:
	- VIP: customers with at least 12 months of history and spending more than 5000
	- REGULAR: customers with at least 12 months of history but spending 5000 or less
	- NEW: customers with a lifespan less than 12 months
And find the total number of customers by each group
*/
WITH customer_segment AS (
	SELECT 
	customer_key,
	first_name,
	last_name,
	total_spending,
	lifespan,
	CASE WHEN total_spending > 5000 AND lifespan >= 12 THEN 'VIP'
		 WHEN total_spending <= 5000 AND lifespan >= 12 THEN 'REGULAR'
		 ELSE 'NEW'
	END AS customer_segment
	FROM(
		SELECT 
		c.customer_key,
		c.first_name,
		c.last_name,
		SUM(s.sales_amount) AS total_spending,
		MIN(s.order_date) AS first_order,
		MAX(s.order_date) AS last_order,
		DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) AS lifespan
		FROM gold.fact_sales s
		LEFT JOIN gold.dim_customers c
		ON s.customer_key = c.customer_key
		GROUP BY c.customer_key, c.first_name, c.last_name
	) t
)

SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
FROM customer_segment
GROUP BY customer_segment
ORDER BY total_customers DESC;

