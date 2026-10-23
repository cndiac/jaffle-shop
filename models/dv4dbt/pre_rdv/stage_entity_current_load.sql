{{ config(materialized='view') }}

{% if var('ingestion_id', none) is none or var('ingestion_id') | string | trim == '' %}
  {{ exceptions.raise_compiler_error('ingestion_id must be provided') }}
{% endif %}

{% set yaml_metadata %}
source_model: stage_entity
ldts: effective_from_date
rsrc: origin_system
include_source_columns: true
enable_ghost_records: false
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

with hashed_stage as (
    {{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
)

select
    ingestion_id,
    effective_from_date,
    current_as_of_date,
    ingestion_load_type,
    is_deleted,
    origin_system,
    origin_system_entity_id,
    entity_name,
    hk_entity_h,
    hd_entity_s
from hashed_stage
where ingestion_id = '{{ var('ingestion_id') | string | replace("'", "''") }}'
