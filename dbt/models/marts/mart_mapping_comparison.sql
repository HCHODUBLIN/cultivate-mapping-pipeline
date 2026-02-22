with auto as (
  select
    a.city,
    a.run_id,
    a.version as run_version,
    a.source_url,
    a.source_url_norm,
    coalesce(r.is_included, false) as is_included
  from {{ ref('stg_automation') }} a
  left join {{ ref('stg_automation_review') }} r
    on a.automation_id = r.automation_id
),

gt as (
  select
    city,
    source_url,
    source_url_norm
  from {{ ref('stg_ground_truth') }}
),

auto_included as (
  select *
  from auto
  where is_included = true
),

overlap as (
  select
    a.city,
    a.run_version,
    count(distinct a.source_url_norm) as overlap_links
  from auto_included a
  inner join gt
    on a.city = gt.city
   and a.source_url_norm = gt.source_url_norm  -- Use normalized URLs for matching
  group by 1,2
),

auto_counts as (
  select
    city,
    run_version,
    count(*) as auto_new_links,
    sum(case when is_included then 1 else 0 end) as auto_valid_links
  from auto
  group by 1,2
),

gt_counts as (
  select
    city,
    count(*) as manual_links
  from gt
  group by 1
)

select
  a.city,
  a.run_version,

  a.auto_new_links,
  a.auto_valid_links,
  a.auto_valid_links * 1.0 / nullif(a.auto_new_links, 0) as auto_valid_rate,

  coalesce(o.overlap_links, 0) as overlap_links,

  g.manual_links,

  coalesce(o.overlap_links, 0) * 1.0 / nullif(g.manual_links, 0) as manual_identified_rate

from auto_counts a
left join overlap o
  on a.city = o.city and a.run_version = o.run_version
left join gt_counts g
  on a.city = g.city
;
