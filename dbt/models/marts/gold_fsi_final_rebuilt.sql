-- models/marts/gold_fsi_final_rebuilt.sql
-- Standardized Gold dataset from gold_fsi_200226 snapshot via seed-driven cleanup + dedup.

with gold_base as (
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
        lat,
        lon
    from {{ ref('int_how_shared_standardized') }}
),

normalized as (
    select
        *,
        -- Dedup within same city only: URL+city, fallback to name+city+country.
        lower(trim(city)) || '|' || coalesce(
            nullif(lower(trim(url)), ''),
            lower(trim(name)) || '|' || lower(trim(country))
        ) as dedup_key,
        -- Prefer rows with richer profile info when duplicates exist.
        (
            iff(nullif(trim(facebook_url), '') is null, 0, 1) +
            iff(nullif(trim(twitter_url), '') is null, 0, 1) +
            iff(nullif(trim(instagram_url), '') is null, 0, 1) +
            iff(lat is null or lon is null, 0, 1)
        ) as completeness_score
    from gold_base
),

ranked as (
    select
        *,
        row_number() over (
            partition by dedup_key
            order by
                completeness_score desc,
                id
        ) as rn
    from normalized
),

final as (
    select
        md5(dedup_key) as id,
        city,
        country,
        name,
        url,
        facebook_url,
        twitter_url,
        instagram_url,
        food_sharing_activities,
        how_it_is_shared,
        lat,
        lon
    from ranked
    where rn = 1
)

select *
from final
