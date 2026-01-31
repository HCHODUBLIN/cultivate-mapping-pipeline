-- models/marts/fsi_activity_summary.sql
-- Analysis of food sharing activities and sharing modes

with fsi_data as (
    select * from {{ source('cultivate', 'gold_fsi_final') }}
),

-- Parse activities array (assuming VARIANT/JSON column)
activities_exploded as (
    select
        id,
        name,
        city,
        country,
        value::string as activity
    from fsi_data,
    lateral flatten(input => parse_json(food_sharing_activities))
),

-- Parse sharing modes array
sharing_modes_exploded as (
    select
        id,
        name,
        city,
        country,
        value::string as sharing_mode
    from fsi_data,
    lateral flatten(input => parse_json(how_it_is_shared))
),

-- Count activities
activity_counts as (
    select
        activity,
        count(distinct id) as fsi_count,
        count(distinct city) as cities_with_activity
    from activities_exploded
    group by activity
),

-- Count sharing modes
sharing_mode_counts as (
    select
        sharing_mode,
        count(distinct id) as fsi_count,
        count(distinct city) as cities_with_mode
    from sharing_modes_exploded
    group by sharing_mode
),

-- Count FSIs with multiple activities
multiple_activities as (
    select
        id,
        count(distinct activity) as num_activities
    from activities_exploded
    group by id
),

activity_distribution as (
    select
        case
            when num_activities = 1 then 'Single activity'
            when num_activities = 2 then 'Two activities'
            when num_activities >= 3 then 'Three or more activities'
        end as activity_category,
        count(*) as fsi_count
    from multiple_activities
    group by
        case
            when num_activities = 1 then 'Single activity'
            when num_activities = 2 then 'Two activities'
            when num_activities >= 3 then 'Three or more activities'
        end
),

total_fsis as (
    select count(distinct id) as total from fsi_data
)

-- Combine results
select
    'Activity' as metric_type,
    activity as metric_name,
    fsi_count,
    round(fsi_count * 100.0 / t.total, 2) as pct_of_total,
    cities_with_activity as num_cities
from activity_counts, total_fsis t

union all

select
    'Sharing Mode' as metric_type,
    sharing_mode as metric_name,
    fsi_count,
    round(fsi_count * 100.0 / t.total, 2) as pct_of_total,
    cities_with_mode as num_cities
from sharing_mode_counts, total_fsis t

union all

select
    'Activity Distribution' as metric_type,
    activity_category as metric_name,
    fsi_count,
    round(fsi_count * 100.0 / t.total, 2) as pct_of_total,
    null as num_cities
from activity_distribution, total_fsis t

order by metric_type, fsi_count desc
