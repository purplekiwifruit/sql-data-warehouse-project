/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'bronze' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Bronze Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/


-- ====================================================================
-- Checking Column(s): Primary Keys
-- ====================================================================
-- Check For Nulls or Duplicates
-- Expectation: No Result
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- ====================================================================
-- Checking Column(s): Data Type of NVARCHAR
-- ====================================================================
-- Check For unwanted Spaces 
-- Expecatation: No result
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);


-- ====================================================================
-- Checking Column(s): Low Cardinality
-- ====================================================================
-- Check for Data Standardization & Consistency
-- Expectation: Low Cardinality Records
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;


-- ====================================================================
-- Checking Column(s): Data Type of INT
-- ====================================================================
-- Check for Nulls or Negative  Numbers
-- Expecation: No result
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;


-- ====================================================================
-- Checking Column(s): Data Type of DATE, DATETIME
-- ====================================================================
-- Check for Invalid Date Orders (End date must be earilier than start date)
-- Expecation: No result
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt 
  
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check for Invalid Date Format
-- Expecation: No result
SELECT sls_order_dt
FROM bronze.crm_sales_details
WHERE 
sls_order_dt <= 0  
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 --Check for date boundary 
OR sls_order_dt < 19000101

-- Check For Out-of-Range Dates
-- Expecation: No result
SELECT DISTINCT bdate 
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

  
-- ====================================================================
-- Checking Column(s): INCLUDE BUSINESS LOGIC
-- ====================================================================
-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-->> Values must not be null, zero or negative

SELECT DISTINCT
sls_sales,
sls_price,
sls_quantity
FROM bronze.crm_sales_details
WHERE sls_price IS NULL OR sls_quantity  IS NULL OR sls_sales IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
OR sls_sales != sls_quantity *sls_price
ORDER BY sls_sales,sls_price,sls_quantity

