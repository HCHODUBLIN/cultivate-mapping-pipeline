-- models/staging/stg_manual_verification.sql
-- Staging model for manual verification results (2025/01 test)

with source as (
    select *
    from {{ source('analysis', 'raw_manual_verification') }}
),

cleaned as (
    select
        city,
        url,
        name as fsi_name,
        is_valid,
        fp_category,
        comments,
        activities,
        how_shared,
        round_version,
        verified_date,
        lat,
        lon,
        file_name,
        loaded_at
    from source
    where city is not null
      and url is not null
),

enriched as (
    select
        *,
        -- Extract round number from version
        case
            when round_version like 'v1.0%' then 1
            when round_version like 'v1.1%' then 2
            when round_version like 'v1.2%' then 3
            when round_version like 'v1.3%' then 4
            when round_version like 'v2.0%' then 5
            else null
        end as round_number,

        -- Categorize FP as broader groups
        case
            when fp_category = 'VALID' then 'Valid'
            when fp_category in ('FP_MEDIA', 'FP_GOVERNMENT') then 'Non-FSI Entity'
            when fp_category in ('FP_COMMERCIAL', 'FP_NON_FSI_ORG') then 'Commercial/Org'
            when fp_category in ('FP_BROKEN_LINK', 'FP_WRONG_LOCATION') then 'Technical Issue'
            when fp_category = 'FP_DUPLICATE' then 'Duplicate'
            else 'Other'
        end as fp_category_group

    from cleaned
)

select * from enriched
