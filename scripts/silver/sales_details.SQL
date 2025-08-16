-- ==============================================================
-- SILVER LAYER: Sales Details
-- --------------------------------------------------------------
-- Script Version: 1.0
-- Source: bronze.crm_sales_details
-- Bronze layer contains raw sales data from source systems
-- This transformation cleanses and standardizes the data for silver layer:
--   1. Convert integer date formats to DATE (if valid)
--   2. Correct sales_sls if missing or inconsistent
--   3. Calculate sales_price if missing or <= 0
--   4. Handle NULLs and invalid values
-- ==============================================================
INSERT INTO silver.crm_sales_details (
    sales_order_num,
    sales_product_key,
    sales_customer_id,
    sales_order_date,
    sales_ship_date,
    sales_due_date,
    sales_sls,
    sales_quantity,
    sales_price
)
SELECT 
    sales_order_num,
    sales_product_key,
    sales_customer_id,
    CASE 
         WHEN sales_order_date = 0 OR LEN(sales_order_date) != 8 THEN NULL
         ELSE CAST(CAST(sales_order_date AS VARCHAR) AS DATE)
    END AS sales_order_date,
    CASE 
         WHEN sales_ship_date = 0 OR LEN(sales_ship_date) != 8 THEN NULL
         ELSE CAST(CAST(sales_ship_date AS VARCHAR) AS DATE)
    END AS sales_ship_date,
    CASE 
         WHEN sales_due_date = 0 OR LEN(sales_due_date) != 8 THEN NULL
         ELSE CAST(CAST(sales_due_date AS VARCHAR) AS DATE)
    END AS sales_due_date,
    CASE 
        WHEN sales_sls IS NULL OR sales_sls <= 0 OR sales_sls != sales_quantity * ABS(sales_price)
            THEN sales_quantity * ABS(sales_price)
        ELSE sales_sls
    END AS sales_sls,
    sales_quantity,
    CASE 
        WHEN sales_price IS NULL OR sales_price <= 0
            THEN sales_sls  / NULLIF(sales_quantity, 0)
        ELSE sales_price
    END AS sales_price
FROM bronze.crm_sales_details
WHERE sales_order_num IS NOT NULL; -- Exclude invalid records

/* ==============================================================
   QA CHECK (Optional) — Bronze vs Silver Comparison
   Uncomment and run to validate transformations
   ==============================================================

SELECT
    b.sales_order_num AS bronze_order_num,
    s.sales_order_num AS silver_order_num,
    
    b.sales_product_key AS bronze_product_key,
    s.sales_product_key AS silver_product_key,
    
    b.sales_customer_id AS bronze_customer_id,
    s.sales_customer_id AS silver_customer_id,
    
    b.sales_order_date AS bronze_order_date,
    s.sales_order_date AS silver_order_date,
    CASE WHEN 
        (CASE WHEN b.sales_order_date = 0 OR LEN(b.sales_order_date) != 8 THEN NULL
              ELSE CAST(CAST(b.sales_order_date AS VARCHAR) AS DATE) END) 
        = s.sales_order_date THEN 'UNCHANGED' ELSE 'CHANGED' END AS order_date_status,
    
    b.sales_ship_date AS bronze_ship_date,
    s.sales_ship_date AS silver_ship_date,
    CASE WHEN 
        (CASE WHEN b.sales_ship_date = 0 OR LEN(b.sales_ship_date) != 8 THEN NULL
              ELSE CAST(CAST(b.sales_ship_date AS VARCHAR) AS DATE) END)
        = s.sales_ship_date THEN 'UNCHANGED' ELSE 'CHANGED' END AS ship_date_status,
    
    b.sales_due_date AS bronze_due_date,
    s.sales_due_date AS silver_due_date,
    CASE WHEN 
        (CASE WHEN b.sales_due_date = 0 OR LEN(b.sales_due_date) != 8 THEN NULL
              ELSE CAST(CAST(b.sales_due_date AS VARCHAR) AS DATE) END)
        = s.sales_due_date THEN 'UNCHANGED' ELSE 'CHANGED' END AS due_date_status,
    
    b.sales_sls AS bronze_sls,
    s.sales_sls AS silver_sls,
    CASE WHEN 
        (CASE WHEN b.sales_sls IS NULL OR b.sales_sls <= 0 OR b.sales_sls != b.sales_quantity * ABS(b.sales_price)
              THEN b.sales_quantity * ABS(b.sales_price) ELSE b.sales_sls END) 
        = s.sales_sls THEN 'UNCHANGED' ELSE 'CHANGED' END AS sls_status,
    
    b.sales_price AS bronze_price,
    s.sales_price AS silver_price,
    CASE WHEN 
        (CASE WHEN b.sales_price IS NULL OR b.sales_price <= 0
              THEN (CASE WHEN b.sales_sls IS NULL OR b.sales_sls <= 0 OR b.sales_sls != b.sales_quantity * ABS(b.sales_price)
                         THEN b.sales_quantity * ABS(b.sales_price)
                         ELSE b.sales_sls END)  / NULLIF(b.sales_quantity,0)
              ELSE b.sales_price END) = s.sales_price 
        THEN 'UNCHANGED' ELSE 'CHANGED' END AS price_status
    
FROM bronze.crm_sales_details b
LEFT JOIN silver.crm_sales_details s
    ON b.sales_order_num = s.sales_order_num
WHERE b.sales_order_num IS NOT NULL
ORDER BY b.sales_order_num;

-- ==============================================================
-- EXAMPLE: Bronze vs Silver Transformation Table
-- | Field             | Bronze Layer (Raw) | Silver Layer (Cleansed) | Transformation Applied                               |
-- |-------------------|------------------|-------------------------|----------------------------------------------------|
-- | sales_order_num   | NULL             | *Excluded*              | Filter invalid records                              |
-- | sales_order_date  | 20240101         | 2024-01-01              | Cast integer to DATE, invalid -> NULL              |
-- | sales_ship_date   | 0                | NULL                    | Invalid date set to NULL                            |
-- | sales_due_date    | 20240301         | 2024-03-01              | Cast integer to DATE                                |
-- | sales_sls         | NULL             | sales_quantity*ABS(price)| Recalculate missing or inconsistent sales value   |
-- | sales_price       | 0                | sales_sls / quantity    | Calculate price if missing or <= 0                 |
-- ==============================================================
