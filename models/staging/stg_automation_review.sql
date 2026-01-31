with base as (
  select
    automation_id,
    is_included
  from {{ source('cultivate', 'raw_automation_reviewed') }}
)

select
  automation_id,
  case
    when upper(trim(is_included)) = 'TRUE' then true
    when upper(trim(is_included)) = 'FALSE' then false
    else null
  end as is_included
from base
