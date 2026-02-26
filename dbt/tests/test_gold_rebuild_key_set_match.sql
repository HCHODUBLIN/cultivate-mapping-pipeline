-- Fail if URL/name/city/country identity keys differ between rebuilt and reference Gold.

with rebuilt as (
    select
        coalesce(
            nullif(lower(trim(url)), ''),
            lower(trim(name)) || '|' || lower(trim(city)) || '|' || lower(trim(country))
        ) as key_norm
    from {{ ref('gold_fsi_final_rebuilt') }}
),
reference as (
    select
        coalesce(
            nullif(lower(trim(url)), ''),
            lower(trim(name)) || '|' || lower(trim(city)) || '|' || lower(trim(country))
        ) as key_norm
    from {{ source('cultivate', 'gold_fsi_200226') }}
),
missing_in_reference as (
    select 'missing_in_reference' as mismatch_type, b.key_norm
    from rebuilt b
    left join reference r on b.key_norm = r.key_norm
    where r.key_norm is null
),
missing_in_rebuilt as (
    select 'missing_in_rebuilt' as mismatch_type, r.key_norm
    from reference r
    left join rebuilt b on b.key_norm = r.key_norm
    where b.key_norm is null
)

select * from missing_in_reference
union all
select * from missing_in_rebuilt
