/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,  -- Surrogate key
	A.cst_id AS customer_id,
	A.cst_key AS customer_number,
	A.cst_firstname AS fist_name,
	A.cst_lastname AS last_name,
	C.cntry AS country,
	A.cst_material_status AS material_status,
	CASE WHEN A.cst_gndr != 'n/a' THEN A.cst_gndr  -- CRM is the primary source for gender
		 ELSE COALESCE(B.gen, 'n/a')  -- Fallback to ERP data
	END AS gender,
	B.bdate AS birthdate,
	A.cst_create_date AS create_date
FROM silver.crm_cust_info A
LEFT JOIN SILVER.erp_cust_az12 B
ON A.cst_key = B.cid
LEFT JOIN SILVER.erp_loc_a101 C
ON A.cst_key = C.cid

  
-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;

CREATE VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER(ORDER BY A.prd_start_dt) AS product_key,   -- Surrogate key
A.prd_id AS product_id,
A.prd_key AS product_number,
A.prd_nm AS product_name,
A.cat_id AS category_id,
B.cat AS category,
B.subcat AS subcategory,
B.maintenance,
A.prd_cost AS cost,
A.prd_line AS product_line,
A.prd_start_dt AS start_date
FROM silver.crm_prd_info A
LEFT JOIN silver.erp_px_cat_g1v2 B
ON A.cat_id = B.id
WHERE A.prd_end_dt IS NULL -- Filter out all historical date

  
-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;

CREATE VIEW gold.fact_sales AS
SELECT
	A.sls_ord_num AS order_numnber ,
	B.product_key, --Dimension Key
	C.customer_key, --Dimension Key
	A.sls_order_dt AS order_date,
	A.sls_ship_dt AS ship_date,
	A.sls_due_dt AS due_date,
	A.sls_sales AS sales_amount,
	A.sls_quantity AS quantity,
	A.sls_price AS price
FROM SILVER.crm_sales_details A
LEFT JOIN gold.dim_products B
ON A.sls_prd_key = B.product_number
LEFT JOIN gold.dim_customers C
ON A.sls_cust_id = C.customer_id
