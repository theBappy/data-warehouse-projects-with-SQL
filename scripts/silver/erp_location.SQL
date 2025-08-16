-- ==============================================================
-- SILVER LAYER: ERP Location A101
-- --------------------------------------------------------------
-- Script Version: 1.0
-- Source: bronze.erp_location_a101
-- Bronze layer contains raw ERP location data
-- This transformation cleanses and standardizes the data for the silver layer:
--   1. Normalize cid by removing '-' characters
--   2. Standardize country codes to full country names
--   3. Replace blank or NULL country values with 'n/a'
-- ==============================================================

INSERT INTO silver.erp_location_a101 (
    cid, 
    cntry
)
SELECT
    REPLACE(cid, '-', '') AS cid,                          -- Remove '-' from cid
    CASE 
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'            -- Standardize country code
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a' -- Handle blank or NULL
        ELSE TRIM(cntry)                                   -- Keep other values as-is
    END AS cntry
FROM bronze.erp_location_a101
WHERE cid IS NOT NULL; -- Exclude invalid IDs

/* ==============================================================
   QA CHECK (Optional) — Bronze vs Silver Comparison
   Uncomment and run to validate transformations
   ==============================================================

SELECT
    b.cid AS bronze_cid,
    s.cid AS silver_cid,
    CASE WHEN REPLACE(b.cid,'-','') = s.cid THEN 'UNCHANGED' ELSE 'CHANGED' END AS cid_status,

    b.cntry AS bronze_cntry,
    s.cntry AS silver_cntry,
    CASE WHEN
        CASE 
            WHEN TRIM(b.cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(b.cntry) IN ('US','USA') THEN 'United States'
            WHEN TRIM(b.cntry) = '' OR b.cntry IS NULL THEN 'n/a'
            ELSE TRIM(b.cntry)
        END = s.cntry THEN 'UNCHANGED' ELSE 'CHANGED' END AS cntry_status
FROM bronze.erp_location_a101 b
LEFT JOIN silver.erp_location_a101 s
    ON REPLACE(b.cid,'-','') = s.cid
WHERE b.cid IS NOT NULL
ORDER BY b.cid;

-- ==============================================================
-- EXAMPLE: Bronze vs Silver Transformation Table
-- | Field   | Bronze Layer (Raw) | Silver Layer (Cleansed) | Transformation Applied           |
-- |---------|------------------|-------------------------|---------------------------------|
-- | cid     | 12-345           | 12345                   | Remove '-'                       |
-- | cid     | 67890            | 67890                   | No change                         |
-- | cntry   | DE               | Germany                 | Standardized from code            |
-- | cntry   | US               | United States           | Standardized from code            |
-- | cntry   | USA              | United States           | Standardized from code            |
-- | cntry   | ''               | n/a                     | Blank value replaced with 'n/a'   |
-- | cntry   | NULL             | n/a                     | NULL replaced with 'n/a'          |
-- | cntry   | FR               | FR                      | Kept as-is                        |
-- ============================================================== */
