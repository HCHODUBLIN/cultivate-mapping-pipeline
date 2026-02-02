-- models/staging/stg_fsi_powerbi_export.sql
-- Silver layer: parse date_checked STRING → DATE, QA validation
-- Source: MART_FSI_POWERBI_EXPORT (bronze/raw, all STRING dates)

with raw as (
    select * from {{ source('cultivate', 'mart_fsi_powerbi_export') }}
),

parsed as (
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
    from raw
)

select * from parsed
