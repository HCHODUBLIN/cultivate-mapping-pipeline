-- models/analysis/fsi_counts.sql
-- Count FSIs by city and folder (replaces count_entries.py)

with data as (
    select
        city,
        folder,
        source_excel as file
    from {{ source('analysis', 'raw_scrape_summary') }}
),

detailed as (
    select
        folder,
        file,
        count(*) as rows
    from data
    group by folder, file
),

summary as (
    select
        folder,
        sum(rows) as total_rows
    from detailed
    group by folder
)

-- Return both detailed and summary in one model
select
    d.folder,
    d.file,
    d.rows,
    s.total_rows as folder_total
from detailed d
left join summary s on d.folder = s.folder
order by d.folder, d.file
