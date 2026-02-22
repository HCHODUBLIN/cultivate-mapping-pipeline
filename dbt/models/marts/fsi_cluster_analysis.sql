-- models/marts/fsi_cluster_analysis.sql
-- Regional cluster analysis for FSI landscape

with city_summary as (
    select * from {{ ref('fsi_city_summary') }}
),

cluster_stats as (
    select
        regional_cluster,
        count(distinct city) as num_cities,
        sum(fsi_count) as total_fsis,
        sum(population) as total_population,
        case
            when sum(population) > 0
            then round(sum(fsi_count) / sum(population) * 100000, 2)
            else 0
        end as fsis_per_100k,
        avg(fsis_per_100k) as avg_fsis_per_100k,
        min(fsi_count) as min_fsis,
        max(fsi_count) as max_fsis,
        round(avg(fsi_count), 1) as avg_fsis_per_city
    from city_summary
    where population > 0  -- Exclude cities without population data
    group by regional_cluster
)

select
    regional_cluster,
    num_cities,
    total_fsis,
    total_population,
    fsis_per_100k,
    round(avg_fsis_per_100k, 2) as avg_fsis_per_100k,
    min_fsis,
    max_fsis,
    avg_fsis_per_city,
    -- Calculate percentage of total FSIs
    round(total_fsis * 100.0 / sum(total_fsis) over (), 2) as pct_of_total_fsis
from cluster_stats
order by fsis_per_100k desc
