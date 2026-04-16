select
    a.url,
    a.status_code,

    -- identity
    m.id,
    m.cityName as city,
    m.city_key,
    m.cityRegion as region,
    m.enterpriseName as name,

    -- contact / location
    m.facebook,
    m.twitter,
    m.address,
    m.lat,
    m.lng,

    -- meta
    m.additionalInfo,
    m.published,

    -- shared resources (Yes/No)
    m.plantsSeeds,
    m.food,
    m.compost,
    m.tools,
    m.land,
    m.kitchenSpaceDevices,
    m.knowledgeSkills,
    m.meals,

    -- sharing modes (Yes/No)
    m.collecting,
    m.gifting,
    m.bartering,
    m.selling,

    -- organisational form (Yes/No)
    m.nonprofits,
    m.socialEnterprises,
    m.forprofit,
    m.cooperatives,
    m.associations,
    m.informal

from {{ ref('int_alive_urls_2016') }} a
left join {{ ref('stg_manual_2016') }} m
    on a.url = m.url
