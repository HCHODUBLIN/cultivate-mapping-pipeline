-- models/intermediate/int_how_shared_standardized.sql
-- Standardize HOW_IT_IS_SHARED values in Bronze data using seed-driven lookup.
-- Splits multi-value field, maps each value via how_shared_mapping seed,
-- then re-aggregates into a clean comma-separated string.
-- Source: bronze_fsi_verified (renamed from GOLD_FSI_200226)

with base as (
    select
        md5(
            lower(trim(city)) || '|' || coalesce(
                nullif(lower(trim(url)), ''),
                lower(trim(name)) || '|' || lower(trim(country))
            )
        ) as id,
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
    from {{ source('cultivate', 'bronze_fsi_verified') }}
),

-- Explode comma-separated how_it_is_shared into individual rows.
exploded as (
    select
        b.id,
        trim(s.value::string) as raw_single_value
    from base b,
        lateral split_to_table(coalesce(b.how_it_is_shared, ''), ',') s
    where trim(s.value::string) != ''
),

-- Map each raw value to canonical via seed lookup (case-insensitive).
mapped as (
    select
        e.id,
        e.raw_single_value,
        m.canonical_value,
        -- Missing data treatment: values outside the 4 canonical categories
        -- (Gifting, Collecting, Selling, Bartering) default to Gifting.
        coalesce(m.canonical_value, 'Gifting') as resolved_value,
        iff(m.canonical_value is null, true, false) as is_unrecognized
    from exploded e
    left join {{ ref('how_shared_mapping') }} m
        on lower(trim(e.raw_single_value)) = m.raw_value
),

-- Re-aggregate into a clean comma-separated string per record.
-- Deduplicate resolved values (e.g. "selling(gifting)" maps to Selling,
-- but Gifting might also appear separately).
reaggregated as (
    select
        id,
        listagg(distinct resolved_value, ', ') within group (order by resolved_value) as how_it_is_shared_clean,
        max(is_unrecognized) as has_unrecognized_value
    from mapped
    group by id
),

-- Join back to base, replacing how_it_is_shared with the cleaned version.
final as (
    select
        b.* exclude (how_it_is_shared),
        coalesce(r.how_it_is_shared_clean, b.how_it_is_shared) as how_it_is_shared,
        coalesce(r.has_unrecognized_value, false) as has_unrecognized_sharing_value
    from base b
    left join reaggregated r on b.id = r.id
)

select * from final
