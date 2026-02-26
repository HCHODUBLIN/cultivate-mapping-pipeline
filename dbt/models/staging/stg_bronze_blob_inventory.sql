-- models/staging/stg_bronze_blob_inventory.sql
-- Compile Bronze blob inventory metadata and map run folders to run labels.

with base as (
    select
        file_path,
        size_bytes,
        md5,
        last_modified,
        regexp_substr(file_path, '[^/]+$') as file_name,
        lower(
            regexp_substr(
                regexp_substr(file_path, '[^/]+$'),
                '\\.([^.]+)$',
                1,
                1,
                'e',
                1
            )
        ) as file_ext,
        regexp_substr(file_path, 'data/bronze/(run-[0-9]+)', 1, 1, 'e', 1) as run_folder
    from {{ source('cultivate', 'bronze_blob_inventory_raw') }}
),

mapped as (
    select
        file_path,
        size_bytes,
        md5,
        last_modified,
        file_name,
        file_ext,
        run_folder,
        try_to_number(regexp_substr(run_folder, '[0-9]+')) as run_number,
        case run_folder
            when 'run-01' then 'run_01'
            when 'run-02' then 'run_02'
            when 'run-03' then 'run_03'
            when 'run-04' then 'run_04'
            else 'run_unknown'
        end as run_label,
        case
            when file_name ilike '.DS_Store' then 'system_file'
            when file_name ilike 'ShareCity200Tracker.xlsx' then 'run01_tracker_xlsx'
            when file_name ilike 'ShareCity200Tracker.csv' then 'run01_tracker_csv'
            when file_path ilike '%/_scraped_text/%/scrape_summary.csv' then 'scrape_summary'
            when file_path ilike '%/_scraped_text/%' and file_ext = 'txt' then 'scraped_text'
            when file_path ilike '%/_scraped_text/%' and file_ext = 'json' then 'scrape_metadata_json'
            when file_name ilike '%_results.xlsx' then 'run_result_xlsx'
            when file_name ilike '%_results.json' then 'run_result_json'
            when regexp_like(file_name, '.*_v[0-9]+\\.[0-9]+\\.[0-9]+\\.xlsx$') then 'versioned_city_xlsx'
            else 'other'
        end as artifact_type,
        case
            when file_path ilike '%/_scraped_text/%'
            then regexp_substr(file_path, '_scraped_text/([^/]+)/', 1, 1, 'e', 1)
            when regexp_like(file_name, '^(.*)_v[0-9]+\\.[0-9]+\\.[0-9]+\\.xlsx$')
            then regexp_substr(file_name, '^(.*)_v[0-9]+\\.[0-9]+\\.[0-9]+\\.xlsx$', 1, 1, 'e', 1)
            when regexp_like(file_name, '^(.*)_results\\.(xlsx|json)$')
            then regexp_substr(file_name, '^(.*)_results\\.(xlsx|json)$', 1, 1, 'e', 1)
            else null
        end as city_name
    from base
)

select
    file_path,
    size_bytes,
    md5,
    last_modified,
    file_name,
    file_ext,
    run_folder,
    run_number,
    run_label,
    artifact_type,
    city_name
from mapped
