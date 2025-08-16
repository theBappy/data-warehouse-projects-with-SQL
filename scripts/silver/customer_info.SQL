-- ==============================================================
-- SILVER LAYER: Customer Information
-- --------------------------------------------------------------
-- Source: bronze.crm_customer_info
-- Bronze layer contains raw, unstandardized data from source systems
-- This transformation cleanses and standardizes the data for silver layer:
--   1. Normalize strings (remove leading/trailing spaces)
--   2. Standardize categorical values (marital status, gender)
--   3. De-duplicate using ROW_NUMBER() to keep the latest record per customer_id
--   4. Exclude invalid records (NULL customer_id)
-- ==============================================================

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
    TRIM(customer_firstname) AS customer_firstname, -- Clean: remove spaces from first name
    TRIM(customer_lastname) AS customer_lastname,   -- Clean: remove spaces from last name
    CASE 
        WHEN UPPER(TRIM(customer_marital_status)) = 'S' THEN 'Single'   -- Standardize: Marital Status
        WHEN UPPER(TRIM(customer_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS customer_marital_status,
    CASE 
        WHEN UPPER(TRIM(customer_gender)) = 'F' THEN 'Female'           -- Standardize: Gender
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
    WHERE customer_id IS NOT NULL -- Filter: Remove null customer IDs
) t
WHERE flag_last = 1; -- Keep only the latest record per customer_id


/* ==============================================================
   QA CHECK (Optional) — Bronze vs Silver Data Comparison
   Uncomment and run to validate transformations
   ==============================================================

SELECT 
    b.customer_id AS bronze_customer_id,
    s.customer_id AS silver_customer_id,
    
    -- First Name
    b.customer_firstname AS bronze_firstname,
    s.customer_firstname AS silver_firstname,
    
    -- Last Name
    b.customer_lastname AS bronze_lastname,
    s.customer_lastname AS silver_lastname,
    
    -- Marital Status
    b.customer_marital_status AS bronze_marital_status,
    s.customer_marital_status AS silver_marital_status,
    
    -- Gender
    b.customer_gender AS bronze_gender,
    s.customer_gender AS silver_gender,
    
    -- Create Date
    b.customer_create_date AS bronze_create_date,
    s.customer_create_date AS silver_create_date
    
FROM bronze.crm_customer_info b
LEFT JOIN silver.crm_customer_info s
    ON b.customer_id = s.customer_id
    AND s.customer_id IS NOT NULL
WHERE b.customer_id IS NOT NULL
ORDER BY b.customer_id;

-- ============================================================== */
