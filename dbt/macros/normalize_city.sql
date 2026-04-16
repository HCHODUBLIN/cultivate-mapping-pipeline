{#-
    normalize_city(col)
    Collapses a city name into a case/accent/punctuation-agnostic key.

    Steps:
      1. split_part(..., ',', 1)  — drop state/region suffix
         ("Ann Arbor, Michigan" → "Ann Arbor")
      2. strip_accents              — fold diacritics
         ("Zürich" → "Zurich", "Bogotá" → "Bogota")
      3. lower                      — case-insensitive
      4. regexp_replace '[^a-z]'    — drop spaces, dots, slashes, etc.
         ("Washington D.C." → "washingtondc")

    Known limitations — alternate names still differ after normalization
    (e.g. Bangalore vs Bengaluru). Handle those with a separate alias map.
-#}
{% macro normalize_city(col) %}
    regexp_replace(
        lower(
            strip_accents(
                split_part(trim({{ col }}), ',', 1)
            )
        ),
        '[^a-z]',
        '',
        'g'
    )
{% endmacro %}
