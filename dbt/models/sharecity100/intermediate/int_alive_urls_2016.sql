-- One row per FSI id in stg_manual_2016 whose URL is alive.
--
-- stg_deadlink_2016 may contain duplicated (city, name, url) rows from
-- the original 2016 export, so we DISTINCT it before the join. With manual
-- (one row per unique id) on the left and dedup'd alive lookup on the
-- right, the result has exactly one row per FSI id that has a live URL.

with alive_dedup as (
    select distinct city, name, url, status_code
    from {{ ref('stg_deadlink_2016') }}
    where alive = true
)

select
    m.id,
    m.cityName       as city,
    m.enterpriseName as name,
    m.url,
    d.status_code
from {{ ref('stg_manual_2016') }} m
inner join alive_dedup d
    on m.cityName       = d.city
   and m.enterpriseName = d.name
   and m.url            = d.url
