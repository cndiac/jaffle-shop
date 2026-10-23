{{
  config(
    materialized=var('entity_stage_materialization', 'table'),
    incremental_strategy='append'
  )
}}

{% set yaml_metadata %}
source_model: entity_source_union
ldts: CURRENT_TIMESTAMP()
rsrc: origin_system
include_source_columns: true
enable_ghost_records: false
derived_columns:
  ingestion_id:
    value: (CAST('{{ var('ingestion_id') | string | replace("'", "''") }}' AS VARCHAR))
    datatype: VARCHAR
  ingestion_load_type:
    value: (CAST('{{ var('entity_ingestion_load_type', 'FULL') | upper }}' AS VARCHAR))
    datatype: VARCHAR
  effective_from_date:
    value: CURRENT_TIMESTAMP()
    datatype: TIMESTAMP_NTZ
hashed_columns:
  hk_entity_h:
    - origin_system
    - origin_system_entity_id
  hd_entity_s:
    is_hashdiff: true
    columns:
      - is_deleted
      - current_as_of_date
      - origin_system
      - origin_system_entity_id
      - entity_name
{% endset %}

with staged_source as (
    {{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
)

select *
from staged_source
