with base as (
  select
    automation_id,
    city,
    run_id,
    source_url
  from {{ source('cultivate', 'raw_automation') }}
)

select
  automation_id,
  lower(trim(city)) as city,
  run_id,
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
  ) as domain,

  -- Extract version from run_id
  regexp_substr(run_id, 'v[0-9]+$') as version

from base
