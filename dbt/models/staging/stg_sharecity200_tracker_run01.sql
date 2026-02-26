-- models/staging/stg_sharecity200_tracker_run01.sql
-- Normalize run-01 ShareCity tracker metadata loaded from ShareCity200Tracker.xlsx.

with src as (
    select
        region,
        country,
        city,
        language,
        sharecity_tier,
        hub_or_spoke,
        priority,
        dcu_fsi_search_plan_week_commencing,
        tcd_manual_check_plan_week_commencing,
        data_entry_size_before_manual_checking,
        manual_review_checker_assigned,
        fsis_searched,
        data_reviewed,
        data_uploaded,
        automation_tool_version,
        comments,
        valid_fsi,
        accuracy_rate,
        correct_name,
        name_accuracy_rate,
        file_name,
        loaded_at
    from {{ source('cultivate', 'raw_sharecity200_tracker_run01') }}
)

select
    trim(region) as region,
    trim(country) as country,
    trim(city) as city,
    trim(language) as language,
    trim(sharecity_tier) as sharecity_tier,
    nullif(trim(hub_or_spoke), '') as hub_or_spoke,
    try_to_number(priority) as priority,
    try_to_date(dcu_fsi_search_plan_week_commencing, 'DD/MM/YYYY') as dcu_fsi_search_plan_week_commencing,
    try_to_date(tcd_manual_check_plan_week_commencing, 'DD/MM/YYYY') as tcd_manual_check_plan_week_commencing,
    try_to_number(data_entry_size_before_manual_checking) as data_entry_size_before_manual_checking,
    nullif(trim(manual_review_checker_assigned), '') as manual_review_checker_assigned,
    nullif(trim(fsis_searched), '') as fsis_searched,
    nullif(trim(data_reviewed), '') as data_reviewed,
    nullif(trim(data_uploaded), '') as data_uploaded,
    nullif(trim(automation_tool_version), '') as automation_tool_version,
    nullif(trim(comments), '') as comments,
    try_to_number(valid_fsi) as valid_fsi,
    try_to_decimal(replace(accuracy_rate, '%', ''), 10, 2) as accuracy_rate_pct,
    try_to_number(correct_name) as correct_name,
    try_to_decimal(replace(name_accuracy_rate, '%', ''), 10, 2) as name_accuracy_rate_pct,
    file_name as source_file_name,
    loaded_at,
    'run-01' as run_folder,
    'ShareCity200Tracker.xlsx' as expected_source_file_name
from src
