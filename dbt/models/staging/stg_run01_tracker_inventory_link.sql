-- models/staging/stg_run01_tracker_inventory_link.sql
-- Connect run-01 tracker with run-01 inventory and recomputed quality metrics.
-- Metric rule:
--   bronze_total_identified_fsi = count from Bronze(run-01) automation records
--   silver_valid_fsi = count from Silver(run-01) records
--   precision_rate_pct = silver_valid_fsi / bronze_total_identified_fsi * 100
-- Note: current Silver source has no version column; Silver is matched by city.

with tracker as (
    select
        city as tracker_city,
        country,
        region,
        language,
        sharecity_tier,
        automation_tool_version,
        lower(regexp_replace(coalesce(automation_tool_version, ''), '^v', '')) as version_key,
        priority,
        source_file_name,
        regexp_replace(lower(coalesce(city, '')), '[^a-z0-9]', '') as city_key
    from {{ ref('stg_sharecity200_tracker_run01') }}
    where run_folder = 'run-01'
),

run01_inventory as (
    select
        file_path,
        file_name,
        artifact_type,
        city_name as inventory_city,
        regexp_replace(lower(coalesce(city_name, '')), '[^a-z0-9]', '') as city_key
    from {{ ref('stg_bronze_blob_inventory') }}
    where run_folder = 'run-01'
      and artifact_type in ('versioned_city_xlsx', 'run_result_xlsx', 'run_result_json')
),

bronze_metrics as (
    select
        regexp_replace(lower(coalesce(city, '')), '[^a-z0-9]', '') as city_key,
        lower(regexp_replace(coalesce(regexp_substr(run_id, 'v[0-9]+(\\.[0-9]+){0,2}', 1, 1, 'i'), ''), '^v', '')) as version_key,
        count(*) as bronze_total_identified_fsi
    from {{ ref('stg_automation') }}
    where run_id is not null
    group by 1, 2
),

silver_metrics as (
    select
        regexp_replace(lower(coalesce(city, '')), '[^a-z0-9]', '') as city_key,
        count(*) as silver_valid_fsi
    from {{ ref('stg_fsi_powerbi_export') }}
    group by 1
),

tracker_file_stats as (
    select
        t.tracker_city,
        t.country,
        t.region,
        t.language,
        t.sharecity_tier,
        t.automation_tool_version,
        t.version_key,
        t.priority,
        t.source_file_name,
        count(i.file_path) as run01_file_count,
        min(i.file_name) as example_run01_file_name
    from tracker t
    left join run01_inventory i
      on t.city_key = i.city_key
    group by
        t.tracker_city,
        t.country,
        t.region,
        t.language,
        t.sharecity_tier,
        t.automation_tool_version,
        t.version_key,
        t.priority,
        t.source_file_name
)

select
    s.tracker_city,
    s.country,
    s.region,
    s.language,
    s.sharecity_tier,
    s.automation_tool_version,
    s.priority,
    s.source_file_name,
    s.run01_file_count,
    s.example_run01_file_name,
    coalesce(b.bronze_total_identified_fsi, 0) as bronze_total_identified_fsi,
    coalesce(v.silver_valid_fsi, 0) as silver_valid_fsi,
    case
        when coalesce(b.bronze_total_identified_fsi, 0) = 0 then null
        else round(coalesce(v.silver_valid_fsi, 0) * 100.0 / b.bronze_total_identified_fsi, 2)
    end as precision_rate_pct,
    case when s.run01_file_count > 0 then true else false end as has_run01_inventory_match
from tracker_file_stats s
left join bronze_metrics b
  on s.version_key = b.version_key
 and regexp_replace(lower(coalesce(s.tracker_city, '')), '[^a-z0-9]', '') = b.city_key
left join silver_metrics v
  on regexp_replace(lower(coalesce(s.tracker_city, '')), '[^a-z0-9]', '') = v.city_key
