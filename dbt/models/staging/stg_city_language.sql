with base as (
  select
    city,
    search_language
  from {{ source('cultivate', 'raw_city_language') }}
)

select
  lower(trim(city)) as city,
  trim(search_language) as search_language
from base
