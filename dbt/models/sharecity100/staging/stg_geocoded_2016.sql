select
    cast(id as varchar)         as id,
    name,
    city,
    country,
    place_id,
    matched_name,
    cast(similarity as double)  as similarity,
    cast(lat as double)         as lat,
    cast(lng as double)         as lng
from {{ source('sharecity100', 'geocoded_2016') }}
