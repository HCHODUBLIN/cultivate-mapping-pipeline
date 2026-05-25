-- Intermediate: 2024 SHARECITY 100 FSIs with full traceability.
--
-- Automation tool output filtered to LLM-valid URLs. Deduped twice:
--   1. per (city, url) — exact URL repeats
--   2. per (city, root_domain) — same org listed under different URL paths /
--      subdomains in the same city (e.g. volunteer.x.org vs www.x.org); the
--      shortest URL (closest to root) is kept. Different root domains with
--      similar names (Tokyo ward food banks) are correctly kept separate.
-- Same URL may still appear under multiple cities (legit multi-city orgs).
-- Geographic outliers (>70km from the city's FSI median) are dropped.
-- Keeps comments / dist_from_city_median_km for QA; fsi_2024 mart selects the
-- clean public subset from this.

with names_dedup as (
    -- one local_name per URL (extract_names recovered the org's own name
    -- from the scraped page; replaces the automation tool's noisy name)
    select distinct on (url) url, local_name
    from {{ source('sharecity100', 'names_2024') }}
    where local_name is not null
),

base as (
    select distinct on (a."City", a."URL")
        -- canonical city + country from master (single source of truth);
        -- fall back to the automation values when the city isn't in master
        coalesce(m.city,    a."City")    as city,
        coalesce(m.country, a."Country") as country,
        -- prefer the initiative's own local-language name; fall back to the
        -- automation name when extract_names had no result for this URL
        coalesce(nullif(n.local_name, ''), a."Name") as name,
        a."URL"                          as url,
        a."Facebook URL"                 as facebook_url,
        a."Twitter URL"                  as twitter_url,
        a."Instagram URL"                as instagram_url,
        a."Food Sharing Activities"      as food_sharing_activities,
        a."How it is Shared"             as how_it_is_shared,
        a."Date Checked"                 as date_checked,
        a."Comments"                     as comments,
        a."Lat"                          as raw_lat,
        a."Lon"                          as raw_lon
    from {{ ref('stg_automation_run01') }} a
    inner join {{ ref('stg_classified_2024') }} c
        on a."URL" = c.url
    left join {{ ref('stg_city_list') }} m
        on {{ normalize_city('a."City"') }} = m.city_key
    left join names_dedup n
        on a."URL" = n.url
    where c.is_valid_fsi = true
      and m.sharecity_tier = 'SC100'  -- drop SC200 cities (multi-city orgs)
    order by a."City", a."URL", a."Name"
),

domain_dedup as (
    -- one row per (city, root_domain); keep the shortest URL (closest to root)
    select distinct on (city, {{ url_root_domain('url') }})
        *
    from base
    order by city, {{ url_root_domain('url') }}, length(url)
),

city_medians as (
    select
        city,
        median(raw_lat) as median_lat,
        median(raw_lon) as median_lon
    from domain_dedup
    where raw_lat is not null
      and raw_lon is not null
    group by city
    having count(*) >= 2
),

with_distance as (
    select
        b.*,
        cm.median_lat,
        cm.median_lon,
        case
            when b.raw_lat is null or cm.median_lat is null then null
            else sqrt(
                power((b.raw_lat - cm.median_lat) * 111.0, 2)
              + power((b.raw_lon - cm.median_lon) * 111.0 * cos(radians(cm.median_lat)), 2)
            )
        end as dist_from_city_median_km
    from domain_dedup b
    left join city_medians cm using (city)
)

select
    city,
    country,
    name,
    url,
    facebook_url,
    twitter_url,
    instagram_url,
    food_sharing_activities,
    how_it_is_shared,
    date_checked,
    comments,

    raw_lat as lat,
    raw_lon as lon,
    dist_from_city_median_km

from with_distance
where coalesce(dist_from_city_median_km, 0) <= 70  -- drop geo outliers entirely
