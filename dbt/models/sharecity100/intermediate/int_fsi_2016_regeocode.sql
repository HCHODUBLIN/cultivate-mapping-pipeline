-- Re-geocode input: non-English-language 2016 FSIs only.
--
-- English-name geocoding is unreliable in non-English countries (misses, or
-- silently wrong matches). int_fsi_2016.name is already the local-language
-- name (coalesce of extract_names local_name → English fallback), so we
-- feed that to Google Places for this subset. English-speaking cities keep
-- their original geocode.

select
    e.id,
    e.name,
    e.city,
    e.country
from {{ ref('int_fsi_2016') }} e
left join {{ ref('stg_city_list') }} m
    on {{ normalize_city('e.city') }} = m.city_key
where coalesce(m.language, 'English') <> 'English'
