-- Intermediate: 2016 SHARECITY 100 FSIs with full traceability.
--
-- Boolean resource columns → Growing / Cooking & Eating / Distribution
-- Boolean sharing columns   → Collecting / Gifting / Bartering / Selling
-- Country looked up from metadata.city_list (cityRegion is a broad region).
-- Coordinates from Google Places, kept only when similarity > 0.5 AND within
-- 70km of the city's FSI median. Keeps id / comments / geocode_* columns for
-- QA; the fsi_2016 mart selects the clean public subset from this.

with names_dedup as (
    -- one local_name per URL (same URL can appear under many cities)
    select distinct on (url) url, local_name
    from {{ source('sharecity100', 'names_2016') }}
    where local_name is not null
),

regeo as (
    -- non-English FSIs re-geocoded with the local-language name
    select
        cast(id as varchar)        as id,
        cast(similarity as double) as similarity,
        cast(lat as double)        as lat,
        cast(lng as double)        as lng
    from {{ source('sharecity100', 'regeocoded_2016') }}
),

normalized as (
    select
        e.id,
        -- canonical city from master (US "City (StateAbbr)"); fall back to
        -- the source value when the city isn't in master
        coalesce(c.city, e.city) as city,
        c.country,
        -- prefer the initiative's own local-language name (extract_names.py),
        -- fall back to the 2016 English name when extraction had no result
        coalesce(nullif(n.local_name, ''), e.name) as name,
        e.url,
        e.facebook as facebook_url,
        e.twitter as twitter_url,
        cast(null as varchar) as instagram_url,

        nullif(concat_ws(';',
            case when e.plantsSeeds = 'Yes'
                  or e.land = 'Yes'
                  or e.compost = 'Yes'
                  or e.tools = 'Yes' then 'Growing' end,
            case when e.kitchenSpaceDevices = 'Yes' then 'Cooking & Eating' end,
            case when e.meals = 'Yes' or e.food = 'Yes' then 'Distribution' end
        ), '') as food_sharing_activities,

        nullif(concat_ws(';',
            case when e.collecting = 'Yes' then 'Collecting' end,
            case when e.gifting = 'Yes' then 'Gifting' end,
            case when e.bartering = 'Yes' then 'Bartering' end,
            case when e.selling = 'Yes' then 'Selling' end
        ), '') as how_it_is_shared,

        cast(null as date) as date_checked,
        e.additionalInfo as comments,

        -- non-English FSIs were re-geocoded with the local-language name;
        -- prefer that result, fall back to the original English-name geocode
        case when coalesce(rg.similarity, g.similarity) > 0.5
             then coalesce(rg.lat, g.lat) end as raw_lat,
        case when coalesce(rg.similarity, g.similarity) > 0.5
             then coalesce(rg.lng, g.lng) end as raw_lon,
        coalesce(rg.similarity, g.similarity) as geocode_similarity,
        case
            when coalesce(rg.similarity, g.similarity) is null then 'no_match'
            when coalesce(rg.similarity, g.similarity) > 0.7   then 'high'
            when coalesce(rg.similarity, g.similarity) > 0.5   then 'medium'
            else                                                    'low'
        end as geocode_confidence

    from {{ ref('int_alive_2016_enriched') }} e
    left join {{ ref('city_aliases') }} a
        on e.city_key = a.alias_key
    left join {{ ref('stg_city_list') }} c
        on coalesce(a.canonical_key, e.city_key) = c.city_key
    left join {{ ref('stg_geocoded_2016') }} g
        on cast(e.id as varchar) = g.id
    left join regeo rg
        on cast(e.id as varchar) = rg.id
    left join names_dedup n
        on e.url = n.url
),

city_medians as (
    select
        city,
        median(raw_lat) as median_lat,
        median(raw_lon) as median_lon
    from normalized
    where raw_lat is not null
      and raw_lon is not null
    group by city
    having count(*) >= 2
),

with_distance as (
    select
        n.*,
        cm.median_lat,
        cm.median_lon,
        case
            when n.raw_lat is null or cm.median_lat is null then null
            else sqrt(
                power((n.raw_lat - cm.median_lat) * 111.0, 2)
              + power((n.raw_lon - cm.median_lon) * 111.0 * cos(radians(cm.median_lat)), 2)
            )
        end as dist_from_city_median_km
    from normalized n
    left join city_medians cm
        on n.city = cm.city
)

select
    id,
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

    -- traceability
    geocode_similarity,
    geocode_confidence,
    dist_from_city_median_km

from with_distance
where coalesce(dist_from_city_median_km, 0) <= 70  -- drop geo outliers entirely
