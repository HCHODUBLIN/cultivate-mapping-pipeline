-- models/marts/accuracy_comparison.sql
-- Compare automation accuracy vs manual verification accuracy
-- Shows how automation improved over rounds

with manual_verification as (
    select
        city,
        round_version,
        round_number,
        total_urls_checked,
        valid_fsis,
        accuracy_pct as manual_accuracy_pct
    from {{ ref('manual_verification_summary') }}
    where round_version != 'All Rounds'
),

-- Placeholder for automation accuracy
-- This would join with raw_automation_reviewed to calculate automation accuracy
automation_baseline as (
    select
        'All Cities' as city,
        'v1.0.0' as round_version,
        1 as round_number,
        228 as total_automation_results,
        73 as automation_valid,
        32.02 as automation_accuracy_pct
    union all
    select
        'All Cities' as city,
        'v1.2.0' as round_version,
        3 as round_number,
        106 as total_automation_results,
        73 as automation_valid,
        68.87 as automation_accuracy_pct
    union all
    select
        'All Cities' as city,
        'v1.3.0' as round_version,
        4 as round_number,
        89 as total_automation_results,
        73 as automation_valid,
        69.6 as automation_accuracy_pct
    union all
    select
        'All Cities' as city,
        'v2.0.0' as round_version,
        5 as round_number,
        null as total_automation_results,
        null as automation_valid,
        74.0 as automation_accuracy_pct  -- Agent-based approach
),

combined as (
    select
        coalesce(m.city, a.city) as city,
        coalesce(m.round_version, a.round_version) as round_version,
        coalesce(m.round_number, a.round_number) as round_number,
        m.total_urls_checked as manual_urls_checked,
        m.valid_fsis as manual_valid_fsis,
        m.manual_accuracy_pct,
        a.total_automation_results,
        a.automation_valid,
        a.automation_accuracy_pct,
        -- Calculate improvement
        round(m.manual_accuracy_pct - a.automation_accuracy_pct, 2) as accuracy_improvement,
        case
            when a.automation_accuracy_pct is not null
            then round(100.0 * (m.manual_accuracy_pct - a.automation_accuracy_pct) / a.automation_accuracy_pct, 2)
            else null
        end as pct_improvement
    from manual_verification m
    full outer join automation_baseline a
        on m.city = a.city
        and m.round_version = a.round_version
)

select * from combined
order by round_number, city
