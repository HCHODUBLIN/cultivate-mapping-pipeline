-- 06_validation.sql
SELECT 'raw_automation' AS table_name, COUNT(*) AS n FROM raw_automation
UNION ALL
SELECT 'raw_automation_reviewed', COUNT(*) FROM raw_automation_reviewed
UNION ALL
SELECT 'raw_city_language', COUNT(*) FROM raw_city_language
UNION ALL
SELECT 'raw_ground_truth', COUNT(*) FROM raw_ground_truth
UNION ALL
SELECT 'raw_cultivate_api', COUNT(*) FROM raw_cultivate_api;

-- Spot-check
SELECT * FROM raw_automation LIMIT 20;
SELECT * FROM raw_automation_reviewed LIMIT 20;
