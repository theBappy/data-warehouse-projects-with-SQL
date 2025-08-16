-- ==============================================================
-- SILVER LAYER: Product Information
-- --------------------------------------------------------------
-- Script Version: 1.0
-- Source: bronze.crm_product_info
-- Bronze layer contains raw product data from source systems
-- This transformation cleanses and standardizes the data for silver layer:
--   1. Extract category_id and product_key from product_key string
--   2. Standardize product_line codes to descriptive names
--   3. Handle NULL product_cost by replacing with 0
--   4. Normalize product_start_date and calculate product_end_date
-- ==============================================================
INSERT INTO silver.crm_product_info (
    product_id,
    category_id,
    product_key,
    product_name,
    product_cost,
    product_line,
    product_start_date,
    product_end_date
)
SELECT
    product_id,
    REPLACE(SUBSTRING(product_key, 1, 5), '-', '_') AS category_id, -- Extract category_id
    SUBSTRING(product_key, 7, LEN(product_key)) AS product_key,       -- Extract product_key
    product_name,
    ISNULL(product_cost, 0) AS product_cost,                           -- Replace NULL with 0
    CASE UPPER(TRIM(product_line))
         WHEN 'M' THEN 'Mountain'
         WHEN 'R' THEN 'Road'
         WHEN 'S' THEN 'Other Sales'
         WHEN 'T' THEN 'Touring'
         ELSE 'n/a'
    END AS product_line,                                               -- Standardize product_line
    CAST(product_start_date AS DATE) AS product_start_date,            -- Normalize start date
    CAST(LEAD(product_start_date) OVER(PARTITION BY product_key ORDER BY product_start_date)-1 AS DATE) AS product_end_date -- Calculate end date
FROM bronze.crm_product_info
WHERE product_id IS NOT NULL; -- Exclude invalid IDs

/* ==============================================================
   QA CHECK (Optional) — Bronze vs Silver Comparison
   Uncomment and run to validate transformations
   ==============================================================

SELECT
    b.product_id AS bronze_product_id,
    s.product_id AS silver_product_id,
    
    b.product_key AS bronze_product_key,
    s.product_key AS silver_product_key,
    
    b.product_name AS bronze_product_name,
    s.product_name AS silver_product_name,
    
    b.product_cost AS bronze_product_cost,
    s.product_cost AS silver_product_cost,
    CASE WHEN ISNULL(b.product_cost,0) = s.product_cost THEN 'UNCHANGED' ELSE 'CHANGED' END AS cost_status,
    
    b.product_line AS bronze_product_line,
    s.product_line AS silver_product_line,
    CASE WHEN
        CASE UPPER(TRIM(b.product_line))
             WHEN 'M' THEN 'Mountain'
             WHEN 'R' THEN 'Road'
             WHEN 'S' THEN 'Other Sales'
             WHEN 'T' THEN 'Touring'
             ELSE 'n/a'
        END = s.product_line THEN 'UNCHANGED' ELSE 'CHANGED' END AS line_status,
    
    CAST(b.product_start_date AS DATE) AS bronze_start_date,
    s.product_start_date AS silver_start_date,
    s.product_end_date AS silver_end_date

FROM bronze.crm_product_info b
LEFT JOIN silver.crm_product_info s
    ON b.product_id = s.product_id
WHERE b.product_id IS NOT NULL
ORDER BY b.product_id;

-- ==============================================================
-- EXAMPLE: Bronze vs Silver Transformation Table
-- | Field               | Bronze Layer (Raw) | Silver Layer (Cleansed) | Transformation Applied                   |
-- |---------------------|------------------|-------------------------|----------------------------------------|
-- | product_id          | NULL             | *Excluded*              | Filter out NULL values                  |
-- | product_key         | "A-12345X"       | "12345X"                | Extract product_key from full key      |
-- | product_key         | "A-12345X"       | "A_12345"               | Extract category_id from first 5 chars |
-- | product_cost        | NULL             | 0                       | Replace NULL with 0                     |
-- | product_line        | "M"              | Mountain                | Standardize code to descriptive name   |
-- | product_line        | "X"              | n/a                     | Non-standard code mapped to 'n/a'      |
-- | product_start_date  | 2024-01-01 12:34 | 2024-01-01              | Cast to DATE                            |
-- | product_end_date    | N/A              | 2024-03-31              | Calculated using LEAD over product_key |
-- ============================================================== */
