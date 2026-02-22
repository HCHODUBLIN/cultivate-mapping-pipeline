-- models/analysis/fsi_dataset_combined.sql
-- Combine all scrape summaries and filter to included FSIs only

with scrape_data as (
    select
        city,
        url,
        url_id,
        text_file,
        row_index,
        source_excel
    from {{ source('analysis', 'raw_scrape_summary') }}
),

included as (
    select url_id
    from {{ ref('fsi_included') }}
),

final as (
    select
        s.city,
        s.url,
        s.url_id,
        s.text_file,
        s.row_index,
        s.source_excel
    from scrape_data s
    inner join included i
        on s.url_id = i.url_id
)

select * from final
