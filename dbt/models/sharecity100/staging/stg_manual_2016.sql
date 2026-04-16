select
    *,
    {{ normalize_city('cityName') }} as city_key
from {{ source('sharecity100', 'manual_2016') }}
where nullif(trim(url), '') is not null
  and nullif(trim(cityName), '') is not null
