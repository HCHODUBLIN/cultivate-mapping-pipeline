-- Silver FSI staging: manually verified subset of bronze.
-- Rows present here were validated; rows missing from bronze are false positives.

with base as (
  select
    run_id,
    source_file,
    city,
    country,
    name,
    url,
    facebook_url,
    twitter_url,
    instagram_url,
    food_sharing_activities,
    how_it_is_shared,
    date_checked,
    comments,
    lat,
    lon
  from {{ source('cultivate', 'raw_silver_fsi') }}
)

select
  run_id,
  source_file,
  lower(trim(city)) as city,
  lower(trim(country)) as country,
  trim(name) as name,
  trim(url) as url,
  trim(facebook_url) as facebook_url,
  trim(twitter_url) as twitter_url,
  trim(instagram_url) as instagram_url,
  trim(food_sharing_activities) as food_sharing_activities,
  trim(how_it_is_shared) as how_it_is_shared,
  trim(date_checked) as date_checked,
  trim(comments) as comments,
  lat,
  lon,

  -- Normalized URL for matching
  lower(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              trim(url),
              '^https?://(www\\.)?', ''
            ),
            '[?#].*$', ''
          ),
          '/+$', ''
        ),
        '''+$', ''
      ),
      '\\s+', ''
    )
  ) as url_norm,

  -- Domain only
  lower(
    regexp_replace(
      regexp_replace(
        trim(url),
        '^https?://(www\\.)?', ''
      ),
      '/.*$', ''
    )
  ) as domain,

  -- Stable row ID
  md5(
    coalesce(lower(trim(url)), '') || '|' ||
    lower(trim(city)) || '|' ||
    lower(trim(country)) || '|' ||
    coalesce(run_id, '')
  ) as id

from base
