-- 06_validation.sql
SELECT 'bronze_automation' AS table_name, COUNT(*) AS n FROM bronze_automation
UNION ALL
SELECT 'bronze_automation_reviewed', COUNT(*) FROM bronze_automation_reviewed
UNION ALL
SELECT 'bronze_city_language', COUNT(*) FROM bronze_city_language
UNION ALL
SELECT 'bronze_ground_truth', COUNT(*) FROM bronze_ground_truth
UNION ALL
SELECT 'bronze_tracker_run01', COUNT(*) FROM bronze_tracker_run01
UNION ALL
SELECT 'bronze_blob_inventory', COUNT(*) FROM bronze_blob_inventory;

-- Spot-check
SELECT * FROM bronze_automation LIMIT 20;
SELECT * FROM bronze_automation_reviewed LIMIT 20;
