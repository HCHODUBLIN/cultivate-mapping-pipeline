-- Input for extract_names.py: 2024 LLM-valid FSIs with scraped text.
-- The automation CSV's `name` column had accents stripped at source
-- (e.g. "Neuklln" → should be "Neukölln"); extract_names.py recovers each
-- initiative's own name from the page text.

select distinct on (s.url)
    s.city,
    s.name,
    s.url,
    s.scraped_text
from {{ ref('stg_scraped_2024') }} s
inner join {{ ref('stg_classified_2024') }} c
    on s.url = c.url
where c.is_valid_fsi = true
  and nullif(trim(s.scraped_text), '') is not null
