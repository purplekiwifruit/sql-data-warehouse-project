/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS


/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
WITH base_query AS (
	SELECT
	s.order_number,
	s.order_date,
	s.customer_key,
	s.sales_amount,
	s.quantity,
	s.price,
	p.product_number,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	P.start_date
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
)

/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
,product_aggregation AS (
	SELECT 
	product_number,
	product_name,
	category, 
	subcategory,
	cost,
	COUNT (order_number) AS total_orders,
	SUM (sales_amount) AS total_sales,
	SUM (quantity) AS total_quantity,
	COUNT(DISTINCT customer_key) AS total_customers,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
	FROM base_query
	GROUP BY product_number, product_name, category, subcategory,cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT
product_number,
product_name,
category, 
subcategory,
cost,
avg_selling_price,
CASE WHEN total_sales > 100000 THEN 'High-Performers'
	 WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Mid-RANGE'
	 ELSE 'Low-Performers'
END AS product_segment,
DATEDIFF(month, last_order, GETDATE()) AS recency,
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales / total_orders 
END AS avg_order_revenue,
CASE WHEN lifespan = 0 THEN 0
	 ELSE total_sales / lifespan
END AS avg_monthly_revenue
FROM product_aggregation
