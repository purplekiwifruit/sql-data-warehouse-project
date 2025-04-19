/*
===============================================================================
Transforamtion Process From Silver to Gold 
===============================================================================
Purpose:
    This file document the transformation steps of customer data 
    from silver layeer to gold layer.
===============================================================================
*/
-- Step 1: Join the Relevant Tables
SELECT
	A.cst_id,
	A.cst_key
	A.cst_firstname,
	A.cst_lastname,
	A.cst_material_status,
	A.cst_gndr,
	A.cst_create_date,
	B.bdate,
	B.gen,
	C.cntry
FROM silver.crm_cust_info A
LEFT JOIN SILVER.erp_cust_az12 B
ON A.cst_key = B.cid
LEFT JOIN SILVER.erp_loc_a101 C
ON A.cst_key = C.cid

-- Step 2: After joining tables, check if duplicate values are introduced to the join result
SELECT cst_id
FROM (
	SELECT
		A.cst_id,
		A.cst_key,
		A.cst_firstname,
		A.cst_lastname,
		A.cst_material_status,
		A.cst_gndr,
		A.cst_create_date,
		B.bdate,
		B.gen,
		C.cntry
	FROM silver.crm_cust_info A
	LEFT JOIN SILVER.erp_cust_az12 B
	ON A.cst_key = B.cid
	LEFT JOIN SILVER.erp_loc_a101 C
	ON A.cst_key = C.cid
) t 
GROUP BY cst_id
HAVING COUNT(*) >1;

--Step 3: Perform Date Integration if there are same inforamtion coming from 2 sources
-- 1. Check the data
SELECT	DISTINCT
	A.cst_gndr,
	B.gen
FROM silver.crm_cust_info A
LEFT JOIN SILVER.erp_cust_az12 B
ON A.cst_key = B.cid
LEFT JOIN SILVER.erp_loc_a101 C
ON A.cst_key = C.cid
ORDER BY 1,2

-- 2. Data Integration according to any Rules
SELECT	DISTINCT
	A.cst_gndr,
	B.gen,
	CASE WHEN A.cst_gndr != 'n/a' THEN A.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(B.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info A
LEFT JOIN SILVER.erp_cust_az12 B
ON A.cst_key = B.cid
LEFT JOIN SILVER.erp_loc_a101 C
ON A.cst_key = C.cid
ORDER BY 1,2

-- 3. Update the Select Query with the new data integaration logic
SELECT
	A.cst_id,
	A.cst_key,
	A.cst_firstname,
	A.cst_lastname,
	A.cst_material_status,
	CASE WHEN A.cst_gndr != 'n/a' THEN A.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(B.gen, 'n/a')
	END AS new_gen,
	A.cst_create_date,
	B.bdate,
	C.cntry
FROM silver.crm_cust_info A
LEFT JOIN SILVER.erp_cust_az12 B
ON A.cst_key = B.cid
LEFT JOIN SILVER.erp_loc_a101 C
ON A.cst_key = C.cid

-- Step 4: 
-- Rename the columns to friendly, meaningful names following the naming convention 
-- Reorder the columns into logical groups to improve readability
-- Gnerate surrogate key
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	A.cst_id AS customer_id,
	A.cst_key AS customer_number,
	A.cst_firstname AS fist_name,
	A.cst_lastname AS last_name,
	C.cntry AS country,
	A.cst_material_status AS material_status,
	CASE WHEN A.cst_gndr != 'n/a' THEN A.cst_gndr 
		 ELSE COALESCE(B.gen, 'n/a')
	END AS gender,
	B.bdate AS birthdate,
	A.cst_create_date AS create_date
FROM silver.crm_cust_info A
LEFT JOIN SILVER.erp_cust_az12 B
ON A.cst_key = B.cid
LEFT JOIN SILVER.erp_loc_a101 C
ON A.cst_key = C.cid
