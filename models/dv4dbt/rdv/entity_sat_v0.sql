{{
  config(
    materialized=var('rdv_materialization', 'incremental'),
    incremental_strategy='append'
  )
}}

{% set yaml_metadata %}
parent_hashkey: hk_entity_h
src_hashdiff: hd_entity_s
src_payload:
  - is_deleted
  - current_as_of_date
  - origin_system_entity_id
  - entity_name
source_model: stage_entity_current_load
src_ldts: effective_from_date
src_rsrc: origin_system
source_is_single_batch: {{ var('source_is_single_batch', true) | lower }}
additional_columns:
  - ingestion_id
  - ingestion_load_type
{% endset %}

with generated_satellite as (
    {{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}
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
from generated_satellite
