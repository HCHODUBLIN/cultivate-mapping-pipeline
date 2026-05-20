{#-
    normalize_city(col)
    Collapses a city name into a case/accent/punctuation-agnostic key.

    Steps:
      1. drop "(StateAbbr)" suffix   — "Boulder (CO)" → "Boulder"
      2. split_part(..., ',', 1)     — drop ", State/Region" suffix
                                       "Ann Arbor, Michigan" → "Ann Arbor"
      3. strip_accents               — "Zürich" → "Zurich", "Bogotá" → "Bogota"
      4. lower                       — case-insensitive
      5. regexp_replace '[^a-z]'     — drop spaces, dots, slashes, parens

    Result: "Boulder, Colorado", "Boulder (CO)", and "Boulder" all collapse
    to the same key "boulder". Alternate names (Bangalore/Bengaluru) still
    need a separate alias map.
-#}
{% macro normalize_city(col) %}
    regexp_replace(
        lower(
            strip_accents(
                split_part(
                    regexp_replace(trim({{ col }}), '\s*\([^)]*\)\s*', '', 'g'),
                    ',', 1
                )
            )
        ),
        '[^a-z]',
        '',
        'g'
    )
{% endmacro %}
