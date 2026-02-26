-- models/staging/stg_fsi_powerbi_export.sql
-- Silver layer normalized to stable schema used by downstream marts.
-- Source: SILVER_FSI_201225

with raw as (
    select * from {{ source('cultivate', 'silver_fsi_201225') }}
),

parsed as (
    select
        -- Source table has no native ID; generate stable deterministic key.
        md5(
            coalesce(
                nullif(lower(trim(url)), ''),
                lower(trim(name)) || '|' || lower(trim(city)) || '|' || lower(trim(country))
            )
        )                                           as id,
        city                                        as city,
        country                                     as country,
        name                                        as name,
        url                                         as url,
        facebook_url                                as facebook_url,
        twitter_url                                 as twitter_url,
        instagram_url                               as instagram_url,
        food_sharing_activities                     as food_sharing_activities,
        how_it_is_shared                            as how_it_is_shared,

        -- Safe date parsing: try multiple formats, NULL on failure
        coalesce(
            try_to_date(date_checked, 'DD/MM/YYYY'),
            try_to_date(date_checked, 'YYYY-MM-DD'),
            try_to_date(date_checked, 'MM/DD/YYYY')
        )                                           as date_checked,

        -- Flag rows where date parsing failed (for QA)
        case
            when date_checked is not null
             and coalesce(
                    try_to_date(date_checked, 'DD/MM/YYYY'),
                    try_to_date(date_checked, 'YYYY-MM-DD'),
                    try_to_date(date_checked, 'MM/DD/YYYY')
                 ) is null
            then true
            else false
        end                                         as date_parse_failed,
        coalesce(
            coalesce(
                try_to_date(date_checked, 'DD/MM/YYYY'),
                try_to_date(date_checked, 'YYYY-MM-DD'),
                try_to_date(date_checked, 'MM/DD/YYYY')
            ) = current_date,
            false
        )                                           as is_recent,

        lat                                         as lat,
        lon                                         as lon,

        -- Not present in this Silver snapshot; keep compatible column.
        null::string                                as round,

        -- Derive boolean flags from text labels.
        iff(coalesce(food_sharing_activities, '') ilike '%Growing%', 1, 0) as growing,
        iff(coalesce(food_sharing_activities, '') ilike '%Distribution%', 1, 0) as distribution,
        iff(coalesce(food_sharing_activities, '') ilike '%Cooking%' and coalesce(food_sharing_activities, '') ilike '%Eating%', 1, 0) as cooking_eating,
        iff(coalesce(how_it_is_shared, '') ilike '%Gifting%', 1, 0) as gifting,
        iff(coalesce(how_it_is_shared, '') ilike '%Collecting%', 1, 0) as collecting,
        iff(coalesce(how_it_is_shared, '') ilike '%Selling%', 1, 0) as selling,
        iff(coalesce(how_it_is_shared, '') ilike '%Bartering%', 1, 0) as bartering
    from raw
)

select * from parsed
