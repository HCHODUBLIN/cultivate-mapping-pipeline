-- Transforms 2016 SHARECITY 100 manual mapping into CULTIVATE 100 schema.
-- Boolean resource columns → Growing / Cooking & Eating / Distribution
-- Boolean sharing columns   → Collecting / Gifting / Bartering / Selling
-- Country looked up from metadata.city_list (cityRegion is a broad region, not a country).

select
    e.city,
    c.country,
    e.name,
    e.url,
    e.facebook as facebook_url,
    e.twitter as twitter_url,
    cast(null as varchar) as instagram_url,

    nullif(concat_ws(';',
        case when e.plantsSeeds = 'Yes'
              or e.land = 'Yes'
              or e.compost = 'Yes'
              or e.tools = 'Yes' then 'Growing' end,
        case when e.kitchenSpaceDevices = 'Yes' then 'Cooking & Eating' end,
        case when e.meals = 'Yes' or e.food = 'Yes' then 'Distribution' end
    ), '') as food_sharing_activities,

    nullif(concat_ws(';',
        case when e.collecting = 'Yes' then 'Collecting' end,
        case when e.gifting = 'Yes' then 'Gifting' end,
        case when e.bartering = 'Yes' then 'Bartering' end,
        case when e.selling = 'Yes' then 'Selling' end
    ), '') as how_it_is_shared,

    cast(null as date) as date_checked,
    e.additionalInfo as comments,
    e.lat,
    e.lng as lon

from {{ ref('int_alive_2016_enriched') }} e
left join {{ ref('stg_city_list') }} c
    on e.city_key = c.city_key
