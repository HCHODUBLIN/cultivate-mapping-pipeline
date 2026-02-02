-- models/marts/mart_fsi_powerbi_export.sql
-- Transforms gold_fsi_final into flat schema expected by Power BI dashboard
-- Renames columns, converts JSON arrays to semicolon-delimited text,
-- and pivots activities/sharing modes into boolean flag columns

with fsi_data as (
    select * from {{ source('cultivate', 'gold_fsi_final') }}
),

transformed as (
    select
        id,
        city,
        country,
        name,
        url,
        facebook_url,
        x_url                                       as twitter_url,
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
        lng                                         as lon,
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
