-- One row per record across all 2026 new-search CSV exports.
-- Column names are already in production camelCase (quoted to preserve case).

select
    "name",
    "url",
    "facebookUrl"           as facebook_url,
    "twitterUrl"            as twitter_url,
    "instagramUrl"          as instagram_url,
    "foodSharingActivities" as food_sharing_activities,
    "howItIsShared"         as how_it_is_shared,
    "country",
    "city",
    cast("latitude"  as double) as lat,
    cast("longitude" as double) as lon,
    cast("dateChecked" as varchar) as date_checked
from {{ source('sharecity100', 'searched_2026') }}
where nullif(trim("url"), '') is not null
