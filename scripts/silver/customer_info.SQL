-- ==============================================================
-- SILVER LAYER: Customer Information
-- --------------------------------------------------------------
-- Script Version: 1.1
-- Source: bronze.crm_customer_info
-- Bronze layer contains raw, unstandardized data from source systems
-- This transformation cleanses and standardizes the data for silver layer:
--   1. Normalize strings (remove leading/trailing spaces)
--   2. Standardize categorical values (marital status, gender)
--   3. De-duplicate using ROW_NUMBER() to keep the latest record per customer_id
--   4. Exclude invalid records (NULL customer_id)
--   5. Tracks ETL execution timestamp for traceability
-- ==============================================================

-- Add ETL run timestamp variable (for documentation/logging if needed)
DECLARE @ETL_Run_Datetime DATETIME = GETDATE();

INSERT INTO silver.crm_customer_info (
    customer_id,
    customer_key,
    customer_firstname,
    customer_lastname,
    customer_marital_status,
    customer_gender,
    customer_create_date
)
SELECT 
    customer_id,
    customer_key,
    TRIM(customer_firstname) AS customer_firstname, -- Clean: remove spaces
    TRIM(customer_lastname) AS customer_lastname,   -- Clean: remove spaces
    CASE 
        WHEN UPPER(TRIM(customer_marital_status)) = 'S' THEN 'Single'  
        WHEN UPPER(TRIM(customer_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS customer_marital_status,
    CASE 
        WHEN UPPER(TRIM(customer_gender)) = 'F' THEN 'Female'           
        WHEN UPPER(TRIM(customer_gender)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS customer_gender,
    customer_create_date
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY customer_create_date DESC
        ) AS flag_last
    FROM bronze.crm_customer_info
    WHERE customer_id IS NOT NULL
) t
WHERE flag_last = 1;

--------------------------------------------------------------------------------
-- QA CHECK (Optional) — Bronze vs Silver Comparison with Change Detection
-- Uncomment and run to validate transformations
--------------------------------------------------------------------------------
/*
SELECT 
    b.customer_id AS bronze_customer_id,
    s.customer_id AS silver_customer_id,

    b.customer_firstname AS bronze_firstname,
    s.customer_firstname AS silver_firstname,
    CASE WHEN TRIM(b.customer_firstname) = s.customer_firstname THEN 'UNCHANGED' ELSE 'CHANGED' END AS firstname_status,

    b.customer_lastname AS bronze_lastname,
    s.customer_lastname AS silver_lastname,
    CASE WHEN TRIM(b.customer_lastname) = s.customer_lastname THEN 'UNCHANGED' ELSE 'CHANGED' END AS lastname_status,

    b.customer_marital_status AS bronze_marital_status,
    s.customer_marital_status AS silver_marital_status,
    CASE WHEN 
        (UPPER(TRIM(b.customer_marital_status)) IN ('S','M') AND s.customer_marital_status IN ('Single','Married'))
        OR (UPPER(TRIM(b.customer_marital_status)) NOT IN ('S','M') AND s.customer_marital_status = 'n/a')
    THEN 'UNCHANGED' ELSE 'CHANGED' END AS marital_status_change,

    b.customer_gender AS bronze_gender,
    s.customer_gender AS silver_gender,
    CASE WHEN 
        (UPPER(TRIM(b.customer_gender)) IN ('F','M') AND s.customer_gender IN ('Female','Male'))
        OR (UPPER(TRIM(b.customer_gender)) NOT IN ('F','M') AND s.customer_gender = 'n/a')
    THEN 'UNCHANGED' ELSE 'CHANGED' END AS gender_change,

    b.customer_create_date AS bronze_create_date,
    s.customer_create_date AS silver_create_date,
    @ETL_Run_Datetime AS etl_run_datetime

FROM bronze.crm_customer_info b
LEFT JOIN silver.crm_customer_info s
    ON b.customer_id = s.customer_id
    AND s.customer_id IS NOT NULL
WHERE b.customer_id IS NOT NULL
ORDER BY b.customer_id;
*/

--------------------------------------------------------------------------------
-- EXAMPLE: Bronze vs Silver Transformation Table (for documentation)
-- | Field                   | Bronze Layer (Raw)   | Silver Layer (Cleansed) | Transformation Applied             |
-- |-------------------------|--------------------|------------------------|------------------------------------|
-- | customer_id             | NULL               | *Excluded*             | Filtered out NULL values           |
-- | customer_firstname      | "  John  "         | John                   | TRIM() removes spaces              |
-- | customer_lastname       | "DOE "             | DOE                    | TRIM() removes spaces              |
-- | customer_marital_status | "s"                | Single                 | Standardized: 'S' -> 'Single'     |
-- | customer_marital_status | "M"                | Married                | Standardized: 'M' -> 'Married'    |
-- | customer_marital_status | "Unknown"          | n/a                    | Non-S/M mapped to 'n/a'           |
-- | customer_gender         | " f "              | Female                 | Standardized: 'F' -> 'Female'     |
-- | customer_gender         | "m"                | Male                   | Standardized: 'M' -> 'Male'       |
-- | customer_create_date    | 2024-03-01 10:00   | 2024-03-01 10:00       | No change                          |
-- | Duplicate records       | Multiple per ID    | Only latest kept       | ROW_NUMBER() + flag_last=1         |
--------------------------------------------------------------------------------
