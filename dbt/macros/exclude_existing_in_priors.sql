{#-
    exclude_existing_in_priors(this_alias, prior_refs)

    SQL fragment for a WHERE clause that drops rows whose (city, root-domain)
    already appears in any earlier dataset. Old data is treated as priority —
    when the same FSI shows up in a new round, the older row is kept and the
    new one is removed.

    Args:
      - this_alias   : alias of the current table in the SELECT (e.g. 'b')
      - prior_refs   : list of dbt refs to older mart names
                       (e.g. ['fsi_2016', 'fsi_2024'])

    Usage:
        from {{ ref('something') }} b
        where {{ exclude_existing_in_priors('b', ['fsi_2016', 'fsi_2024']) }}

    Matching rule mirrors the in-dataset dedup: same canonical city and
    same registered root domain (via url_root_domain macro).
-#}
{% macro exclude_existing_in_priors(this_alias, prior_refs) %}
not exists (
    select 1 from (
        {% for m in prior_refs %}
        {% if not loop.first %}union all{% endif %}
        select city, {{ url_root_domain('url') }} as root_domain
        from {{ ref(m) }}
        {% endfor %}
    ) priors
    where priors.city = {{ this_alias }}.city
      and priors.root_domain = {{ url_root_domain(this_alias ~ '.url') }}
)
{% endmacro %}
