-- Canonical city/country/language lookup — single source of truth.
--
-- Sourced from sharecity200_tracker (has Language). Applies the rules used
-- by downstream marts and exports:
--   - country: "United Kingdom" → "UK", "United States" → "US", others unchanged
--   - city: for US, canonical form "City (StateAbbr)"
--           (e.g. "Boulder, Colorado" → "Boulder (CO)").
--           Non-US: kept as the tracker spells it.
--   - city_key: normalized via the normalize_city macro (same key whether
--               you start from "Boulder", "Boulder, Colorado", or "Boulder (CO)").

with tracker as (
    select
        "Region"   as region,
        "Country"  as country_raw,
        "City"     as city_raw,
        "Language" as language,
        "Priority" as priority
    from {{ source('metadata', 'sharecity200_tracker') }}
    where nullif(trim("City"), '') is not null  -- drop trailing blank rows
),

-- US cities arrive as "Boulder, Colorado" → split into name + state name
us_split as (
    select
        *,
        case when country_raw = 'United States'
             then trim(split_part(city_raw, ',', 1)) end as us_city_name,
        case when country_raw = 'United States'
             then trim(split_part(city_raw, ',', 2)) end as us_state_name
    from tracker
)

select
    region,
    case
        when country_raw = 'United Kingdom' then 'UK'
        when country_raw = 'United States'  then 'US'
        else country_raw
    end as country,

    case
        when country_raw = 'United States' and sc.state_code is not null
             then us_city_name || ' (' || sc.state_code || ')'
        else city_raw
    end as city,

    language,
    priority,
    {{ normalize_city('city_raw') }} as city_key

from us_split
left join {{ ref('us_state_codes') }} sc
    on us_split.us_state_name = sc.state_name
