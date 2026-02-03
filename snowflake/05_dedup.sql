-- 05_dedup.sql
-- Duplicate checks (no deletes)

CREATE OR REPLACE VIEW v_dupes_raw_automation AS
SELECT automation_id, city, run_id, source_url, COUNT(*) AS n
FROM raw_automation
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW v_dupes_mart_fsi_powerbi AS
SELECT id, COUNT(*) AS n
FROM MART_FSI_POWERBI_EXPORT
GROUP BY 1
HAVING COUNT(*) > 1;
