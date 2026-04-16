select
    *,
    {{ normalize_city('cityName') }} as city_key
from {{ source('sharecity100', 'manual_2016') }}
where url is not null
