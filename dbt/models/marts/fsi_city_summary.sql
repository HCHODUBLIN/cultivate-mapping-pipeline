-- models/marts/fsi_city_summary.sql
-- City-level FSI statistics for 105 cities landscape analysis

with fsi_data as (
    select * from {{ source('cultivate', 'gold_fsi_final') }}
),

city_counts as (
    select
        city,
        country,
        count(*) as fsi_count,
        count(distinct id) as unique_fsis
    from fsi_data
    group by city, country
),

-- Population data (manually entered from census/city data)
-- TODO: Load from external reference table if available
city_populations as (
    select 'Barcelona' as city, 'Spain' as country, 1385000 as population, 'Southern Europe' as cluster
    union all select 'Utrecht', 'Netherlands', 345000, 'Western Europe'
    union all select 'Milan', 'Italy', 1243000, 'Southern Europe'
    union all select 'Bordeaux', 'France', 258000, 'Western Europe'
    union all select 'Turin', 'Italy', 803000, 'Southern Europe'
    union all select 'Lyon', 'France', 510000, 'Western Europe'
    union all select 'Dublin', 'Republic of Ireland', 1074000, 'Western Europe'
    union all select 'Nantes', 'France', 320000, 'Western Europe'
    union all select 'Brighton and Hove', 'United Kingdom', 290000, 'Western Europe'
    union all select 'Marseille', 'France', 820000, 'Western Europe'
    union all select 'Dresden', 'Germany', 550000, 'Western Europe'
    union all select 'Bari', 'Italy', 320000, 'Southern Europe'
    union all select 'Seville', 'Spain', 660000, 'Southern Europe'
    union all select 'Antwerp', 'Belgium', 520000, 'Western Europe'
    union all select 'Liege', 'Belgium', 195000, 'Western Europe'
    union all select 'Cork', 'Republic of Ireland', 220000, 'Western Europe'
    union all select 'Graz', 'Austria', 290000, 'Western Europe'
    union all select 'Auckland', 'New Zealand', 1400000, 'Other / Neighbourhood'
    union all select 'Innsbruck', 'Austria', 135000, 'Western Europe'
    union all select 'Brno', 'Czech Republic', 380000, 'Eastern Europe'
    union all select 'Ljubljana', 'Slovenia', 295000, 'Southern Europe'
    -- Add more cities as needed
),

city_stats as (
    select
        c.city,
        c.country,
        c.fsi_count,
        coalesce(p.population, 0) as population,
        coalesce(p.cluster, 'Unknown') as regional_cluster,
        case
            when p.population > 0
            then round(c.fsi_count / p.population * 100000, 2)
            else 0
        end as fsis_per_100k
    from city_counts c
    left join city_populations p
        on c.city = p.city
        and c.country = p.country
)

select
    city,
    country,
    fsi_count,
    population,
    fsis_per_100k,
    regional_cluster,
    -- Rankings
    row_number() over (order by fsi_count desc) as rank_by_count,
    row_number() over (order by fsis_per_100k desc) as rank_by_per_capita,
    row_number() over (partition by regional_cluster order by fsi_count desc) as rank_within_cluster
from city_stats
order by fsi_count desc
