-- Mart: SHARECITY 100 unified FSI dataset (2016 + 2024).
--
-- Combines fsi_2016 (manual mapping) with fsi_2024 (automation + LLM).
-- 2016 takes priority — when the same FSI URL appears in both years (within
-- the same city, exact or near-identical URL), the 2024 row is dropped.
--
-- A `dataset_year` column tags the source year for downstream filtering.

with norm as (
    select
        url,
        lower(trim(city)) as city_key,
        regexp_replace(
            regexp_replace(
                regexp_replace(lower(trim(url)), '^https?://', ''),
                '^www\.', ''
            ),
            '\.[a-z]{2,3}/?$', ''
        ) as url_norm
    from {{ ref('fsi_2024') }}
),

dup_2024_urls as (
    -- 2024 URLs that already exist in 2016 (same city, exact or near URL)
    select distinct n.url as url_2024
    from norm n
    inner join (
        select
            url,
            lower(trim(city)) as city_key,
            regexp_replace(
                regexp_replace(
                    regexp_replace(lower(trim(url)), '^https?://', ''),
                    '^www\.', ''
                ),
                '\.[a-z]{2,3}/?$', ''
            ) as url_norm
        from {{ ref('fsi_2016') }}
    ) o
        on n.city_key = o.city_key
       and (n.url = o.url
            or jaro_winkler_similarity(n.url_norm, o.url_norm) > 0.85)
)

select
    'sc2016' as dataset_year,
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
    lat,
    lon
from {{ ref('fsi_2016') }}

union all

select
    'sc2024' as dataset_year,
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
    lat,
    lon
from {{ ref('fsi_2024') }}
where url not in (select url_2024 from dup_2024_urls)
