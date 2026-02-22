with auto as (
  select
    lower(city) as city,
    regexp_substr(run_id, 'v[0-9]+$') as run_version,
    source_url,
    coalesce(r.is_included, false) as is_included
  from {{ ref('stg_automation') }} a
  left join {{ ref('stg_automation_review') }} r
    on a.automation_id = r.automation_id
),

gt as (
  select lower(city) as city, source_url
  from {{ ref('stg_ground_truth') }}
),

auto_total as (
  select count(*) as n
  from auto
),

auto_valid as (
  select count(*) as n
  from auto
  where is_included = true
),

auto_valid_by_version as (
  select run_version, count(*) as n
  from auto
  where is_included = true
  group by 1
),

overlap_total as (
  select count(distinct a.city || '|' || a.source_url) as n
  from auto a
  join gt
    on a.city = gt.city and a.source_url = gt.source_url
  where a.is_included = true
),

overlap_by_version as (
  select
    a.run_version,
    count(distinct a.city || '|' || a.source_url) as n
  from auto a
  join gt
    on a.city = gt.city and a.source_url = gt.source_url
  where a.is_included = true
  group by 1
),

manual_total as (
  select count(*) as n
  from gt
)

select
  (select n from auto_total) as total_new_links_through_automation,
  (select n from auto_valid) as total_valid_new_fsi_links,
  (select n from auto_valid) * 1.0 / nullif((select n from auto_total),0) as valid_rate_over_all_new_links,

  max(case when run_version='v1' then n end) as valid_new_fsi_links_v1,
  max(case when run_version='v2' then n end) as valid_new_fsi_links_v2,

  (select n from overlap_total) as overlap_links_with_ground_truth,
  max(case when run_version='v1' then n end) as overlap_v1,
  max(case when run_version='v2' then n end) as overlap_v2,

  (select n from manual_total) as manual_links_total,
  max(case when run_version='v1' then n end) * 1.0 / nullif((select n from manual_total),0) as manual_identified_in_v1_rate

from overlap_by_version
full join auto_valid_by_version using (run_version);
