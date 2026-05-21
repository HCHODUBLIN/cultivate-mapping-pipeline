{#-
    url_root_domain(col)
    Extract the registered (root) domain from a URL.

    Strips protocol + path, then captures the last 2 labels — or the last 3
    when the URL ends in a 2-segment TLD (.co.uk, .edu.tr, .com.au, …),
    detected as "<=3-char label>.<2-char country code>" at the end.

    Examples:
      https://www.capitalareafoodbank.org/x      → capitalareafoodbank.org
      https://volunteer.capitalareafoodbank.org  → capitalareafoodbank.org
      https://kurumsaliletisim.medeniyet.edu.tr  → medeniyet.edu.tr
-#}
{% macro url_root_domain(col) %}
    regexp_extract(
        split_part(regexp_replace(lower(trim({{ col }})), '^https?://', ''), '/', 1),
        '([a-z0-9-]+\.[a-z]{2,3}\.[a-z]{2}|[a-z0-9-]+\.[a-z]{2,})$'
    )
{% endmacro %}
