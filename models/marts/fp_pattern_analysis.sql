-- models/marts/fp_pattern_analysis.sql
-- Analyze false positive patterns across cities and rounds

with verification_data as (
    select * from {{ ref('stg_manual_verification') }}
    where is_valid = false  -- Only false positives
),

fp_by_category as (
    select
        fp_category,
        fp_category_group,
        city,
        round_version,
        count(*) as fp_count
    from verification_data
    group by fp_category, fp_category_group, city, round_version
),

fp_totals as (
    select
        sum(fp_count) as total_fps
    from fp_by_category
),

fp_with_percentages as (
    select
        f.fp_category,
        f.fp_category_group,
        f.city,
        f.round_version,
        f.fp_count,
        round(100.0 * f.fp_count / t.total_fps, 2) as pct_of_total_fps
    from fp_by_category f
    cross join fp_totals t
),

category_summary as (
    select
        fp_category,
        fp_category_group,
        'All Cities' as city,
        'All Rounds' as round_version,
        sum(fp_count) as fp_count,
        sum(pct_of_total_fps) as pct_of_total_fps
    from fp_with_percentages
    group by fp_category, fp_category_group
)

-- Combine detailed and summary
select * from fp_with_percentages
union all
select * from category_summary
order by fp_count desc
