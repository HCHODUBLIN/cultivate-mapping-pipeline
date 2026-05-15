-- Finds likely overlap between 2016 SHARECITY entries and 2024 automation
-- output, prioritising recall (catch as many true duplicates as possible).
--
-- Compares each 2016/2024 pair within the same city across four signals:
--   1. exact URL match
--   2. URL similarity (Jaro-Winkler, protocol/www/TLD stripped)
--   3. domain-only similarity (just host, no path)
--   4. name similarity (Jaro-Winkler)
--
-- Each pair gets a `match_strength` so downstream models can choose how
-- aggressive to be:
--   - 'exact'   — same URL exactly
--   - 'strong'  — same domain OR URL similarity > 0.85 + name similarity > 0.5
--   - 'medium'  — URL similarity > 0.7 OR (name > 0.7 AND url > 0.5)
--   - 'weak'    — name similarity > 0.6 (alone)

with d2016 as (
    select
        id          as id_2016,
        lower(trim(city)) as city_key,
        lower(trim(name)) as name_norm,
        regexp_replace(
            regexp_replace(
                regexp_replace(lower(trim(url)), '^https?://', ''),
                '^www\.', ''
            ),
            '\.[a-z]{2,3}/?$', ''
        ) as url_norm,
        -- domain only: strip protocol/www, then take part before first /
        split_part(
            regexp_replace(
                regexp_replace(lower(trim(url)), '^https?://', ''),
                '^www\.', ''
            ),
            '/', 1
        ) as domain,
        name,
        url
    from {{ ref('fsi_2016') }}
    where url is not null
),

d2024 as (
    select
        url         as url_2024_raw,
        lower(trim(city)) as city_key,
        lower(trim(name)) as name_norm,
        regexp_replace(
            regexp_replace(
                regexp_replace(lower(trim(url)), '^https?://', ''),
                '^www\.', ''
            ),
            '\.[a-z]{2,3}/?$', ''
        ) as url_norm,
        split_part(
            regexp_replace(
                regexp_replace(lower(trim(url)), '^https?://', ''),
                '^www\.', ''
            ),
            '/', 1
        ) as domain,
        name,
        url
    from {{ ref('stg_scraped_2024') }}
    where url is not null
),

scored as (
    select
        a.city_key                                              as city,
        a.id_2016,
        a.name                                                  as name_2016,
        a.url                                                   as url_2016,
        b.name                                                  as name_2024,
        b.url                                                   as url_2024,
        jaro_winkler_similarity(a.name_norm, b.name_norm)       as name_sim,
        jaro_winkler_similarity(a.url_norm,  b.url_norm)        as url_sim,
        jaro_winkler_similarity(a.domain,    b.domain)          as domain_sim,
        case when a.domain = b.domain then 1 else 0 end         as same_domain
    from d2016 a
    inner join d2024 b
        on a.city_key = b.city_key
)

select
    *,
    case
        when url_2016 = url_2024                                       then 'exact'
        when same_domain = 1                                            then 'strong'
        when url_sim > 0.85 and name_sim > 0.5                          then 'strong'
        when url_sim > 0.7                                              then 'medium'
        when name_sim > 0.7 and url_sim > 0.5                           then 'medium'
        when name_sim > 0.6                                             then 'weak'
    end as match_strength

from scored
where url_2016 = url_2024
   or same_domain = 1
   or url_sim > 0.7
   or name_sim > 0.6
