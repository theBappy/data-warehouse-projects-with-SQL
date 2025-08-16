-- ==============================================================
-- SILVER LAYER: ERP Customer AZ12
-- --------------------------------------------------------------
-- Script Version: 1.0
-- Source: bronze.erp_customer_az12
-- Bronze layer contains raw ERP customer data
-- This transformation cleanses and standardizes the data for the silver layer:
--   1. Normalize cid (remove 'NAS' prefix if present)
--   2. Filter invalid birth dates (bdate in future → NULL)
--   3. Standardize gender codes to descriptive names
-- ==============================================================

INSERT INTO silver.erp_customer_az12(
    cid, 
    bdate, 
    gen
)
SELECT
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
         ELSE cid
    END AS cid,                                      -- Remove 'NAS' prefix if exists
    CASE WHEN bdate > GETDATE() THEN NULL
         ELSE bdate
    END AS bdate,                                    -- Set future birth dates to NULL
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen                                        -- Standardize gender
FROM bronze.erp_customer_az12
WHERE cid IS NOT NULL; -- Exclude invalid IDs

/* ==============================================================
   QA CHECK (Optional) — Bronze vs Silver Comparison
   Uncomment and run to validate transformations
   ==============================================================

SELECT
    b.cid AS bronze_cid,
    s.cid AS silver_cid,
    CASE WHEN 
        (CASE WHEN b.cid LIKE 'NAS%' THEN SUBSTRING(b.cid,4,LEN(b.cid)) ELSE b.cid END) 
        = s.cid THEN 'UNCHANGED' ELSE 'CHANGED' END AS cid_status,
    
    b.bdate AS bronze_bdate,
    s.bdate AS silver_bdate,
    CASE WHEN (CASE WHEN b.bdate > GETDATE() THEN NULL ELSE b.bdate END) = s.bdate 
         THEN 'UNCHANGED' ELSE 'CHANGED' END AS bdate_status,
    
    b.gen AS bronze_gen,
    s.gen AS silver_gen,
    CASE WHEN 
        CASE 
            WHEN UPPER(TRIM(b.gen)) IN ('F','FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(b.gen)) IN ('M','MALE') THEN 'Male'
            ELSE 'n/a'
        END = s.gen THEN 'UNCHANGED' ELSE 'CHANGED' END AS gen_status
FROM bronze.erp_customer_az12 b
LEFT JOIN silver.erp_customer_az12 s
    ON (CASE WHEN b.cid LIKE 'NAS%' THEN SUBSTRING(b.cid,4,LEN(b.cid)) ELSE b.cid END) = s.cid
WHERE b.cid IS NOT NULL
ORDER BY b.cid;

-- ==============================================================
-- EXAMPLE: Bronze vs Silver Transformation Table
-- | Field   | Bronze Layer (Raw) | Silver Layer (Cleansed) | Transformation Applied                  |
-- |---------|------------------|-------------------------|----------------------------------------|
-- | cid     | NAS12345         | 12345                   | Removed 'NAS' prefix if exists         |
-- | cid     | 98765            | 98765                   | No change                               |
-- | bdate   | 20300101         | NULL                    | Future date set to NULL                 |
-- | bdate   | 19850315         | 1985-03-15              | Valid date cast as-is                    |
-- | gen     | f                | Female                  | Standardized 'F' / 'FEMALE' → 'Female' |
-- | gen     | m                | Male                    | Standardized 'M' / 'MALE' → 'Male'     |
-- | gen     | unknown          | n/a                     | Non-standard values → 'n/a'             |
-- ============================================================== */
