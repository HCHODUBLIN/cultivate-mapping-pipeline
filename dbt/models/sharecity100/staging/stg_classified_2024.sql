select
    city,
    name,
    url,
    cast(valid as boolean) as is_valid_fsi,
    confidence,
    reason,
    nullif(error, '') as error
from {{ source('sharecity100', 'classified_2024') }}
