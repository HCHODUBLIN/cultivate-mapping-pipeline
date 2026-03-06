-- Bronze vs Silver comparison: precision metrics per city and run_id.
-- Bronze = all automation-discovered FSIs.
-- Silver = subset of bronze after manual review (false positives removed).
-- Precision = silver_count / bronze_count (what % of automation results are valid).

with bronze_counts as (
  select
    city,
    country,
    run_id,
    count(*) as bronze_fsi_count
  from {{ ref('stg_bronze_fsi') }}
  group by city, country, run_id
),

silver_counts as (
  select
    city,
    country,
    run_id,
    count(*) as silver_fsi_count
  from {{ ref('stg_silver_fsi') }}
  group by city, country, run_id
)

select
  b.city,
  b.country,
  b.run_id,
  b.bronze_fsi_count,
  coalesce(s.silver_fsi_count, 0) as silver_fsi_count,
  b.bronze_fsi_count - coalesce(s.silver_fsi_count, 0) as false_positive_count,
  case
    when b.bronze_fsi_count > 0
    then round(coalesce(s.silver_fsi_count, 0) * 100.0 / b.bronze_fsi_count, 2)
    else 0
  end as precision_pct

from bronze_counts b
left join silver_counts s
  on b.city = s.city
  and b.country = s.country
  and b.run_id = s.run_id

order by b.country, b.city, b.run_id
