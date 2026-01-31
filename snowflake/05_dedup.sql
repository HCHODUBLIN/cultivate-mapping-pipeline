-- 05_dedup.sql
-- Duplicate checks (no deletes)

CREATE OR REPLACE VIEW v_dupes_raw_automation AS
SELECT automation_id, city, run_id, source_url, COUNT(*) AS n
FROM raw_automation
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;
