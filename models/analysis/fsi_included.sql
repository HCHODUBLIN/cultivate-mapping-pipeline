-- models/analysis/fsi_included.sql
-- Filter to only included FSIs

select
    url_id,
    city,
    url,
    loaded_at
from {{ ref('fsi_filter_results') }}
where decision = 'include'
