-- Mart: 2024 SHARECITY 100 FSIs.
--
-- Original automation tool output, filtered to URLs that the LLM classified
-- as a valid FSI. One row per (city, url) — deduped because the automation
-- export sometimes contained the same FSI multiple times within a single city.
-- The same URL may still appear under multiple cities (legit multi-city orgs).
--
-- Geographic outlier check (same as fsi_2016): coords beyond 70km of the
-- city's FSI median are nulled out. The automation tool used Google Places
-- too, but a few entries still ended up in the wrong country.

with base as (
    select distinct on (a."City", a."URL")
        a."City"                       as city,
        a."Country"                    as country,
        a."Name"                       as name,
        a."URL"                        as url,
        a."Facebook URL"               as facebook_url,
        a."Twitter URL"                as twitter_url,
        a."Instagram URL"              as instagram_url,
        a."Food Sharing Activities"    as food_sharing_activities,
        a."How it is Shared"           as how_it_is_shared,
        a."Date Checked"               as date_checked,
        a."Comments"                   as comments,
        a."Lat"                        as raw_lat,
        a."Lon"                        as raw_lon
    from {{ ref('stg_automation_run01') }} a
    inner join {{ ref('stg_classified_2024') }} c
        on a."URL" = c.url
    where c.is_valid_fsi = true
    order by a."City", a."URL", a."Name"
),

city_medians as (
    select
        city,
        median(raw_lat) as median_lat,
        median(raw_lon) as median_lon
    from base
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
    from base b
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
