with base as (
  select
    ground_truth_id,
    city,
    source_url
  from {{ source('cultivate', 'raw_ground_truth') }}
)

select
  ground_truth_id,
  lower(trim(city)) as city,
  source_url,

  -- Normalized URL for matching
  lower(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              trim(source_url),
              '^https?://(www\\.)?',  -- Remove http(s):// and optional www.
              ''
            ),
            '[?#].*$',  -- Remove query params and fragments
            ''
          ),
          '/+$',  -- Remove trailing slashes
          ''
        ),
        '''+$',  -- Remove trailing quotes
        ''
      ),
      '\\s+',  -- Remove any whitespace
      ''
    )
  ) as source_url_norm,

  -- Domain only (for domain-level matching)
  lower(
    regexp_replace(
      regexp_replace(
        trim(source_url),
        '^https?://(www\\.)?',  -- Remove http(s):// and optional www.
        ''
      ),
      '/.*$',  -- Remove everything after first slash
      ''
    )
  ) as domain

from base
