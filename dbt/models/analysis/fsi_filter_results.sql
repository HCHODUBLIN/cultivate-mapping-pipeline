-- models/analysis/fsi_filter_results.sql
-- Load FSI filter results (include/exclude decisions from LLM)

with base as (
    select
        url_id,
        decision,
        city,
        url,
        loaded_at
    from {{ source('analysis', 'raw_fsi_filter_results') }}
)

select
    url_id,
    lower(trim(decision)) as decision,
    city,
    url,
    loaded_at
from base
where url_id is not null
