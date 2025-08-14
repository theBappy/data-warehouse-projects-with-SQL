
/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicategorye primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_customer_info'
-- ====================================================================
-- Check for NULLs or Duplicategoryes in Primary Key
-- Expectation: No Results
SELECT 
    customeromer_id,
    COUNT(*) 
FROM silver.crm_customer_info
GROUP BY customeromer_id
HAVING COUNT(*) > 1 OR customeromer_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    customeromer_key 
FROM silver.crm_customer_info
WHERE customeromer_key != TRIM(customeromer_key);

-- Data Standardization & Consistency
SELECT DISTINCT 
    customeromer_marital_status 
FROM silver.crm_customer_info;

-- ====================================================================
-- Checking 'silver.crm_product_info'
-- ====================================================================
-- Check for NULLs or Duplicategoryes in Primary Key
-- Expectation: No Results
SELECT 
    product_id,
    COUNT(*) 
FROM silver.crm_product_info
GROUP BY product_id
HAVING COUNT(*) > 1 OR product_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    product_nm 
FROM silver.crm_product_info
WHERE product_nm != TRIM(product_nm);

-- Check for NULLs or Negative Values in Cost
-- Expectation: No Results
SELECT 
    product_cost 
FROM silver.crm_product_info
WHERE product_cost < 0 OR product_cost IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT 
    product_line 
FROM silver.crm_product_info;

-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_product_info
WHERE product_end_dt < product_start_dt;

-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================
-- Check for Invalid Dates
-- Expectation: No Invalid Dates
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
    OR LEN(sls_due_dt) != 8 
    OR sls_due_dt > 20500101 
    OR sls_due_dt < 19000101;

-- Check for Invalid Date Orders (Order Date > Shipping/Due Dates)
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT DISTINCT 
    sales_sls,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sales_sls != sls_quantity * sls_price
   OR sales_sls IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sales_sls <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sales_sls, sls_quantity, sls_price;

-- ====================================================================
-- Checking 'silver.erp_customer_az12'
-- ====================================================================
-- Identify Out-of-Range Dates
-- Expectation: Birthdates between 1924-01-01 and Today
SELECT DISTINCT 
    bdate 
FROM silver.erp_customer_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT 
    gen 
FROM silver.erp_customer_az12;

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================
-- Data Standardization & Consistency
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ====================================================================
-- Checking 'silver.erp_px_category_g1v2'
-- ====================================================================
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    * 
FROM silver.erp_px_category_g1v2
WHERE category != TRIM(category) 
   OR subcategory != TRIM(subcategory) 
   OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_category_g1v2;
