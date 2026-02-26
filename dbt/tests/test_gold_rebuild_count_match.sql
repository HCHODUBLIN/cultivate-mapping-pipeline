-- Fail if rebuilt Gold row count differs from reference Gold snapshot.

with rebuilt as (
    select count(*) as n
    from {{ ref('gold_fsi_final_rebuilt') }}
),
reference as (
    select count(*) as n
    from {{ source('cultivate', 'gold_fsi_200226') }}
)

select
    rebuilt.n as rebuilt_count,
    reference.n as reference_count
from rebuilt
cross join reference
where rebuilt.n <> reference.n
