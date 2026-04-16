select
    city,
    name,
    url,
    status_code
from {{ ref('stg_deadlink_2016') }}
where alive = true
