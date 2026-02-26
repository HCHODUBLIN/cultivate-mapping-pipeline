-- models/marts/mart_fsi_powerbi_export.sql
-- Transforms gold_fsi_200226 into flat schema expected by Power BI dashboard
-- Renames columns, converts JSON arrays to semicolon-delimited text,
-- and pivots activities/sharing modes into boolean flag columns

with fsi_data as (
    select
        *,
        md5(coalesce(url, '') || '|' || coalesce(name, '') || '|' || coalesce(city, '') || '|' || coalesce(country, '')) as fsi_id
    from {{ source('cultivate', 'gold_fsi_200226') }}
),

transformed as (
    select
        fsi_id                                     as id,
        city,
        country,
        name,
        url,
        facebook_url,
        twitter_url,
        instagram_url,

        -- JSON array → semicolon-separated text
        array_to_string(
            parse_json(food_sharing_activities), ';'
        )                                           as food_sharing_activities,

        array_to_string(
            parse_json(how_it_is_shared), ';'
        )                                           as how_it_is_shared,

        null::string                                as date_checked,
        lat,
        lon,
        null::string                                as round,

        -- Boolean flags: food_sharing_activities
        case
            when array_contains(
                'Growing'::variant,
                parse_json(food_sharing_activities)
            ) then 1 else 0
        end                                         as growing,

        case
            when array_contains(
                'Distribution'::variant,
                parse_json(food_sharing_activities)
            ) then 1 else 0
        end                                         as distribution,

        case
            when array_contains(
                'Cooking & Eating'::variant,
                parse_json(food_sharing_activities)
            ) then 1 else 0
        end                                         as cooking_eating,

        -- Boolean flags: how_it_is_shared
        case
            when array_contains(
                'Gifting'::variant,
                parse_json(how_it_is_shared)
            ) then 1 else 0
        end                                         as gifting,

        case
            when array_contains(
                'Collecting'::variant,
                parse_json(how_it_is_shared)
            ) then 1 else 0
        end                                         as collecting,

        case
            when array_contains(
                'Selling'::variant,
                parse_json(how_it_is_shared)
            ) then 1 else 0
        end                                         as selling,

        case
            when array_contains(
                'Bartering'::variant,
                parse_json(how_it_is_shared)
            ) then 1 else 0
        end                                         as bartering

    from fsi_data
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
    lat,
    lon,
    round,
    growing,
    distribution,
    cooking_eating,
    gifting,
    collecting,
    selling,
    bartering
from transformed
order by id
