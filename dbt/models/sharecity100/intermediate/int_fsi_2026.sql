-- Intermediate: 2026 new-search FSIs with the same cleaning rules as 2024.
--
-- - dedup per (city, root_domain) keeping the shortest URL (collapses same
--   org listed under different paths/subdomains)
-- - canonical city + country from the master (UK/US abbrev, "City (StateAbbr)")
-- - drop geographic outliers (>70km from city's FSI median)
--
-- Each 2026 CSV is one city; SC100-only by definition (Lisbon excluded).

with base as (
    select distinct on (s.city, {{ url_root_domain('s.url') }})
        coalesce(m.city,    s.city)    as city,
        coalesce(m.country, s.country) as country,
        s.name,
        s.url,
        s.facebook_url,
        s.twitter_url,
        s.instagram_url,
        s.food_sharing_activities,
        s.how_it_is_shared,
        s.date_checked,
        s.lat as raw_lat,
        s.lon as raw_lon
    from {{ ref('stg_searched_2026') }} s
    left join {{ ref('stg_city_list') }} m
        on {{ normalize_city('s.city') }} = m.city_key
    order by s.city, {{ url_root_domain('s.url') }}, length(s.url) asc, s.name
),

city_medians as (
    select
        city,
        median(raw_lat) as median_lat,
        median(raw_lon) as median_lon
    from base
    where raw_lat is not null and raw_lon is not null
    group by city
    having count(*) >= 2
),

with_distance as (
    select
        b.*,
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
    city, country, name, url,
    facebook_url, twitter_url, instagram_url,
    food_sharing_activities, how_it_is_shared,
    date_checked,
    raw_lat as lat,
    raw_lon as lon,
    dist_from_city_median_km
from with_distance wd
where coalesce(dist_from_city_median_km, 0) <= 70  -- drop geo outliers entirely
  and {{ exclude_existing_in_priors('wd', ['fsi_2016', 'fsi_2024']) }}
