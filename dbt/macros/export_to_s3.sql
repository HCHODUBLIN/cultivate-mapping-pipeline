{#-
    export_to_s3(schema, table, s3_path)
    Writes any DuckDB table/view to a single CSV on S3.

    Uses DuckDB's COPY TO with the httpfs extension; the S3 secret defined
    in profiles.yml provides credentials.

    Usage:
        dbt run-operation export_to_s3 --args "
            {schema: sharecity100,
             table: int_2016_cultivate_normalized,
             s3_path: 's3://cultivate-mapping-data/raw/sharecity100/2016/to_geocode.csv'}
        "
-#}
{% macro export_to_s3(schema, table, s3_path) %}
    {% set sql %}
        copy (select * from {{ schema }}.{{ table }})
        to '{{ s3_path }}' (format csv, header true)
    {% endset %}
    {% do run_query(sql) %}
    {% do log("Exported " ~ schema ~ "." ~ table ~ " → " ~ s3_path, info=True) %}
{% endmacro %}
