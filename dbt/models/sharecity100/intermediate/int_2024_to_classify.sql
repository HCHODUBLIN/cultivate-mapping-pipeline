-- URLs from 2024 SHARECITY automation that still need LLM classification.
--
-- Excludes URLs already confidently matched to a 2016 entry (exact or strong
-- in int_2016_2024_overlap) — those reuse the 2016 manual classification.
-- Medium and weak overlaps are kept here for now (decision deferred).

with strong_matches as (
    select distinct url_2024
    from {{ ref('int_2016_2024_overlap') }}
    where match_strength in ('exact', 'strong')
)

select s.*
from {{ ref('stg_scraped_2024') }} s
left join strong_matches m
    on s.url = m.url_2024
where m.url_2024 is null
