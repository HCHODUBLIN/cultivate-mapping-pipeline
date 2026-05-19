-- Mart: 2024 SHARECITY 100 FSIs — public schema, matches production export.
-- Detailed/QA columns (comments, dist_from_city_median_km) live in int_fsi_2024.

select
    name,
    url,
    facebook_url             as "facebookUrl",
    twitter_url              as "twitterUrl",
    instagram_url            as "instagramUrl",
    food_sharing_activities  as "foodSharingActivities",
    how_it_is_shared         as "howItIsShared",
    country,
    city,
    lat                      as latitude,
    lon                      as longitude,
    date_checked             as "dateChecked"
from {{ ref('int_fsi_2024') }}
