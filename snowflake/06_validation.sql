-- 06_validation.sql
SELECT 'raw_automation' AS table_name, COUNT(*) AS n FROM raw_automation
UNION ALL
SELECT 'raw_automation_reviewed', COUNT(*) FROM raw_automation_reviewed
UNION ALL
SELECT 'raw_city_language', COUNT(*) FROM raw_city_language
UNION ALL
SELECT 'raw_ground_truth', COUNT(*) FROM raw_ground_truth
UNION ALL
SELECT 'raw_sharecity200_tracker_run01', COUNT(*) FROM raw_sharecity200_tracker_run01
UNION ALL
SELECT 'bronze_blob_inventory_raw', COUNT(*) FROM bronze_blob_inventory_raw
UNION ALL
SELECT 'silver_fsi_201225', COUNT(*) FROM SILVER_FSI_201225
UNION ALL
SELECT 'gold_fsi_200226', COUNT(*) FROM gold_fsi_200226;

-- Spot-check
SELECT * FROM raw_automation LIMIT 20;
SELECT * FROM raw_automation_reviewed LIMIT 20;
SELECT * FROM SILVER_FSI_201225 LIMIT 20;
