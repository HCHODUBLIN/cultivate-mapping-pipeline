-- models/intermediate/int_run01_tracker_inventory_link.sql
-- Connect run-01 tracker with run-01 inventory and recomputed quality metrics.
-- Metric rule:
--   bronze_total_identified_fsi = count from Bronze(run-01) automation records
--   verified_fsi = count from reviewed automation records (is_included = TRUE)
--   precision_rate_pct = verified_fsi / bronze_total_identified_fsi * 100

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
        regexp_extract(file_path, '[^/]+$') as file_name,
        regexp_replace(lower(coalesce(
            regexp_extract(file_path, 'run-01/([^/]+)/', 1),
            ''
        )), '[^a-z0-9]', '') as city_key
    from {{ source('cultivate', 'bronze_blob_inventory') }}
    where file_path ilike '%run-01%'
),

bronze_metrics as (
    select
        regexp_replace(lower(coalesce(city, '')), '[^a-z0-9]', '') as city_key,
        lower(regexp_replace(coalesce(regexp_extract(run_id, 'v[0-9]+(\.[0-9]+){0,2}'), ''), '^v', '')) as version_key,
        count(*) as bronze_total_identified_fsi
    from {{ ref('stg_automation') }}
    where run_id is not null
    group by 1, 2
),

verified_metrics as (
    select
        regexp_replace(lower(coalesce(a.city, '')), '[^a-z0-9]', '') as city_key,
        count(*) as verified_fsi
    from {{ ref('stg_automation') }} a
    inner join {{ ref('stg_automation_review') }} r
        on a.automation_id = r.automation_id
    where upper(r.is_included) = 'TRUE'
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
    coalesce(v.verified_fsi, 0) as verified_fsi,
    case
        when coalesce(b.bronze_total_identified_fsi, 0) = 0 then null
        else round(coalesce(v.verified_fsi, 0) * 100.0 / b.bronze_total_identified_fsi, 2)
    end as precision_rate_pct,
    case when s.run01_file_count > 0 then true else false end as has_run01_inventory_match
from tracker_file_stats s
left join bronze_metrics b
  on s.version_key = b.version_key
 and regexp_replace(lower(coalesce(s.tracker_city, '')), '[^a-z0-9]', '') = b.city_key
left join verified_metrics v
  on regexp_replace(lower(coalesce(s.tracker_city, '')), '[^a-z0-9]', '') = v.city_key
