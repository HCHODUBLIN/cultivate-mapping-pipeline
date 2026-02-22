-- models/marts/fsi_deduplication_impact.sql
-- Comparison of pre-deduplication vs post-deduplication FSI counts
-- Shows impact of deduplication process by city

with pre_dedup as (
    select
        city,
        country,
        count(*) as fsi_count_before,
        count(distinct url) as unique_urls_before
    from {{ source('cultivate', 'bronze_sharecity200_raw') }}
    group by city, country
),

post_dedup as (
    select
        city,
        country,
        count(*) as fsi_count_after,
        count(distinct url) as unique_urls_after
    from {{ source('cultivate', 'gold_fsi_final') }}
    group by city, country
),

comparison as (
    select
        coalesce(pre.city, post.city) as city,
        coalesce(pre.country, post.country) as country,
        coalesce(pre.fsi_count_before, 0) as fsi_count_before,
        coalesce(post.fsi_count_after, 0) as fsi_count_after,
        coalesce(pre.fsi_count_before, 0) - coalesce(post.fsi_count_after, 0) as duplicates_removed,
        case
            when pre.fsi_count_before > 0
            then round((coalesce(pre.fsi_count_before, 0) - coalesce(post.fsi_count_after, 0)) * 100.0 / pre.fsi_count_before, 2)
            else 0
        end as dedup_rate_pct,
        -- City status
        case
            when pre.fsi_count_before is null then 'Added in final'
            when post.fsi_count_after is null then 'Removed entirely'
            when pre.fsi_count_before = post.fsi_count_after then 'No duplicates'
            else 'Duplicates found'
        end as status
    from pre_dedup pre
    full outer join post_dedup post
        on pre.city = post.city
        and pre.country = post.country
),

-- Add summary stats
summary_stats as (
    select
        'TOTAL' as city,
        'All Cities' as country,
        sum(fsi_count_before) as fsi_count_before,
        sum(fsi_count_after) as fsi_count_after,
        sum(duplicates_removed) as duplicates_removed,
        round(sum(duplicates_removed) * 100.0 / sum(fsi_count_before), 2) as dedup_rate_pct,
        'Summary' as status
    from comparison
)

-- Combine city-level and summary
select * from comparison
union all
select * from summary_stats
order by
    case when city = 'TOTAL' then 1 else 0 end,  -- Summary row first
    duplicates_removed desc,  -- Then cities with most duplicates
    city
