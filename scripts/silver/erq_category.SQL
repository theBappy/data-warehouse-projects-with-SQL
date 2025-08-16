-- ==============================================================
-- SILVER LAYER: ERP PX Category G1V2
-- --------------------------------------------------------------
-- Script Version: 1.0
-- Source: bronze.erp_px_cat_g1v2
-- Bronze layer contains raw ERP category data
-- This transformation cleanses and standardizes the data for the silver layer:
--   1. Copy all fields as-is (no transformation needed in this case)
--   2. Ensure invalid IDs are excluded
-- ==============================================================

INSERT INTO silver.erp_px_cat_g1v2(
    id,
    category,
    subcategory,
    maintenance
)
SELECT
    id,
    category,
    subcategory,
    maintenance
FROM bronze.erp_px_cat_g1v2
WHERE id IS NOT NULL; -- Exclude invalid IDs

/* ==============================================================
   QA CHECK (Optional) — Bronze vs Silver Comparison
   Uncomment and run to validate transformations
   ==============================================================

SELECT
    b.id AS bronze_id,
    s.id AS silver_id,
    CASE WHEN b.id = s.id THEN 'UNCHANGED' ELSE 'CHANGED' END AS id_status,
    
    b.category AS bronze_category,
    s.category AS silver_category,
    CASE WHEN b.category = s.category THEN 'UNCHANGED' ELSE 'CHANGED' END AS category_status,
    
    b.subcategory AS bronze_subcategory,
    s.subcategory AS silver_subcategory,
    CASE WHEN b.subcategory = s.subcategory THEN 'UNCHANGED' ELSE 'CHANGED' END AS subcategory_status,
    
    b.maintenance AS bronze_maintenance,
    s.maintenance AS silver_maintenance,
    CASE WHEN b.maintenance = s.maintenance THEN 'UNCHANGED' ELSE 'CHANGED' END AS maintenance_status
FROM bronze.erp_px_cat_g1v2 b
LEFT JOIN silver.erp_px_cat_g1v2 s
    ON b.id = s.id
WHERE b.id IS NOT NULL
ORDER BY b.id;

-- ==============================================================
-- EXAMPLE: Bronze vs Silver Transformation Table
-- | Field        | Bronze Layer (Raw) | Silver Layer (Cleansed) | Transformation Applied  |
-- |--------------|------------------|-------------------------|------------------------|
-- | id           | NULL             | *Excluded*              | Filter invalid IDs     |
-- | category     | CAT001           | CAT001                  | Copied as-is           |
-- | subcategory  | SUB01            | SUB01                   | Copied as-is           |
-- | maintenance  | Y                | Y                       | Copied as-is           |
-- ============================================================== */
