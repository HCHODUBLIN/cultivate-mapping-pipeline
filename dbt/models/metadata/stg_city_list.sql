select
    "Region"    as region,
    "Country"   as country,
    "City"      as city,
    "Priority"  as priority,
    {{ normalize_city('"City"') }} as city_key
from {{ source('metadata', 'city_list') }}
where nullif(trim("City"), '') is not null  -- drop trailing blank CSV rows
