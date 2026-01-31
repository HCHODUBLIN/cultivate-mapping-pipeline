-- stg_ground_truth_enhanced.sql
-- Enhanced version with path segment extraction for similarity matching
-- Extends stg_ground_truth with additional fields for multi-level matching

with base as (
  select * from {{ ref('stg_ground_truth') }}
)

select
  ground_truth_id,
  city,
  source_url,
  source_url_norm,
  domain,

  -- Path segments extraction
  -- First path segment (e.g., facebook.com/groups/abc -> "groups")
  lower(
    regexp_substr(
      regexp_replace(
        source_url_norm,
        '^[^/]+/',  -- Remove domain and first slash
        ''
      ),
      '^[^/?#]+'  -- Extract first segment before /, ?, or #
    )
  ) as path_segment_1,

  -- Second path segment (e.g., facebook.com/groups/abc -> "abc")
  lower(
    regexp_substr(
      regexp_replace(
        regexp_replace(
          source_url_norm,
          '^[^/]+/',  -- Remove domain and first slash
          ''
        ),
        '^[^/]+/',  -- Remove first segment and slash
        ''
      ),
      '^[^/?#]+'  -- Extract second segment
    )
  ) as path_segment_2,

  -- Combined: domain + first path segment
  -- Useful for matching facebook.com/groups/* separately from facebook.com/events/*
  case
    when regexp_substr(regexp_replace(source_url_norm, '^[^/]+/', ''), '^[^/?#]+') is not null
    then domain || '/' || lower(regexp_substr(regexp_replace(source_url_norm, '^[^/]+/', ''), '^[^/?#]+'))
    else domain
  end as domain_path1,

  -- URL depth (number of path segments)
  -- Helps identify if it's a simple domain vs deep page
  array_size(
    split(
      regexp_replace(source_url_norm, '^[^/]+/', ''),  -- Remove domain
      '/'
    )
  ) as url_depth

from base
