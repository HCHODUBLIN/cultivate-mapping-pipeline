-- Mart: 2026 new-search FSIs — public schema, matches production export.
-- Cleaning rules (root-domain dedup, geo outlier drop) live in int_fsi_2026.

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
from {{ ref('int_fsi_2026') }}
