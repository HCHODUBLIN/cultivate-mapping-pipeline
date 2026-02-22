-- models/marts/manual_verification_summary.sql
-- Summary statistics by city and round for manual verification

with verification_data as (
    select * from {{ ref('stg_manual_verification') }}
),

city_round_summary as (
    select
        city,
        round_version,
        round_number,
        count(*) as total_urls_checked,
        sum(case when is_valid = true then 1 else 0 end) as valid_fsis,
        sum(case when is_valid = false then 1 else 0 end) as false_positives,
        round(
            100.0 * sum(case when is_valid = true then 1 else 0 end) / nullif(count(*), 0),
            2
        ) as accuracy_pct
    from verification_data
    group by city, round_version, round_number
),

city_overall_summary as (
    select
        city,
        'All Rounds' as round_version,
        0 as round_number,
        count(*) as total_urls_checked,
        sum(case when is_valid = true then 1 else 0 end) as valid_fsis,
        sum(case when is_valid = false then 1 else 0 end) as false_positives,
        round(
            100.0 * sum(case when is_valid = true then 1 else 0 end) / nullif(count(*), 0),
            2
        ) as accuracy_pct
    from verification_data
    group by city
),

all_cities_round_summary as (
    select
        'All Cities' as city,
        round_version,
        round_number,
        count(*) as total_urls_checked,
        sum(case when is_valid = true then 1 else 0 end) as valid_fsis,
        sum(case when is_valid = false then 1 else 0 end) as false_positives,
        round(
            100.0 * sum(case when is_valid = true then 1 else 0 end) / nullif(count(*), 0),
            2
        ) as accuracy_pct
    from verification_data
    group by round_version, round_number
),

all_cities_overall_summary as (
    select
        'All Cities' as city,
        'All Rounds' as round_version,
        0 as round_number,
        count(*) as total_urls_checked,
        sum(case when is_valid = true then 1 else 0 end) as valid_fsis,
        sum(case when is_valid = false then 1 else 0 end) as false_positives,
        round(
            100.0 * sum(case when is_valid = true then 1 else 0 end) / nullif(count(*), 0),
            2
        ) as accuracy_pct
    from verification_data
),

combined as (
    select * from city_round_summary
    union all
    select * from city_overall_summary
    union all
    select * from all_cities_round_summary
    union all
    select * from all_cities_overall_summary
)

select
    city,
    round_version,
    round_number,
    total_urls_checked,
    valid_fsis,
    false_positives,
    accuracy_pct,
    -- Add rankings
    row_number() over (partition by round_version order by accuracy_pct desc) as accuracy_rank
from combined
order by city, round_number
