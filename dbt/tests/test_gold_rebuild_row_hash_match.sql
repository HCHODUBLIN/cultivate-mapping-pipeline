-- Fail if canonicalized row content differs between rebuilt and reference Gold.
-- Ignores rebuilt synthetic id and compares business columns only.

with rebuilt as (
    select
        md5(
            coalesce(lower(trim(country)), '') || '|' ||
            coalesce(lower(trim(city)), '') || '|' ||
            coalesce(lower(trim(name)), '') || '|' ||
            coalesce(lower(trim(url)), '') || '|' ||
            coalesce(lower(trim(instagram_url)), '') || '|' ||
            coalesce(lower(trim(twitter_url)), '') || '|' ||
            coalesce(lower(trim(facebook_url)), '') || '|' ||
            coalesce(trim(food_sharing_activities), '') || '|' ||
            coalesce(trim(how_it_is_shared), '') || '|' ||
            coalesce(to_varchar(lon), '') || '|' ||
            coalesce(to_varchar(lat), '') || '|' ||
            ''  -- comments not present in rebuilt model
        ) as row_hash
    from {{ ref('gold_fsi_final_rebuilt') }}
),
reference as (
    select
        md5(
            coalesce(lower(trim(country)), '') || '|' ||
            coalesce(lower(trim(city)), '') || '|' ||
            coalesce(lower(trim(name)), '') || '|' ||
            coalesce(lower(trim(url)), '') || '|' ||
            coalesce(lower(trim(instagram_url)), '') || '|' ||
            coalesce(lower(trim(twitter_url)), '') || '|' ||
            coalesce(lower(trim(facebook_url)), '') || '|' ||
            coalesce(trim(food_sharing_activities), '') || '|' ||
            coalesce(trim(how_it_is_shared), '') || '|' ||
            coalesce(to_varchar(lon), '') || '|' ||
            coalesce(to_varchar(lat), '') || '|' ||
            ''  -- ignore comments for parity (not in rebuilt output)
        ) as row_hash
    from {{ source('cultivate', 'gold_fsi_200226') }}
),
missing_in_reference as (
    select 'missing_in_reference' as mismatch_type, b.row_hash
    from rebuilt b
    left join reference r on b.row_hash = r.row_hash
    where r.row_hash is null
),
missing_in_rebuilt as (
    select 'missing_in_rebuilt' as mismatch_type, r.row_hash
    from reference r
    left join rebuilt b on b.row_hash = r.row_hash
    where b.row_hash is null
)

select * from missing_in_reference
union all
select * from missing_in_rebuilt
