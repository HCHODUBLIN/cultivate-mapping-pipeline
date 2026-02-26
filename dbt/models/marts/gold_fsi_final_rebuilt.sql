-- models/marts/gold_fsi_final_rebuilt.sql
-- Rebuild canonical Gold dataset from Silver snapshot via deterministic deduplication.

with silver_base as (
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
        lat,
        lon
    from {{ ref('stg_fsi_powerbi_export') }}
),

normalized as (
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
        lat,
        lon,
        -- Prefer URL-level identity; fallback to name+city+country.
        coalesce(
            nullif(lower(trim(url)), ''),
            lower(trim(name)) || '|' || lower(trim(city)) || '|' || lower(trim(country))
        ) as dedup_key,
        -- Prefer rows with richer profile info when duplicates exist.
        (
            iff(nullif(trim(facebook_url), '') is null, 0, 1) +
            iff(nullif(trim(twitter_url), '') is null, 0, 1) +
            iff(nullif(trim(instagram_url), '') is null, 0, 1) +
            iff(lat is null or lon is null, 0, 1)
        ) as completeness_score
    from silver_base
),

ranked as (
    select
        *,
        row_number() over (
            partition by dedup_key
            order by
                completeness_score desc,
                date_checked desc nulls last,
                id
        ) as rn
    from normalized
),

final as (
    select
        -- Stable deterministic identifier for rebuilt gold records.
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
