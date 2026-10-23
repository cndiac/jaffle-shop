{{
  config(
    materialized=var('stage_entity_materialization', 'table'),
    incremental_strategy='append'
  )
}}

select
    '{{ var('ingestion_id') | string | replace("'", "''") }}' as ingestion_id,
    current_timestamp() as effective_from_date,
    current_as_of_date,
    '{{ var('load_type') | upper }}' as ingestion_load_type,
    is_deleted,
    origin_system,
    origin_system_entity_id,
    entity_name
from {{ ref(var('source_model')) }}
