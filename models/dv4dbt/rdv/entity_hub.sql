{{
  config(
    materialized=var('rdv_materialization', 'incremental'),
    incremental_strategy='append'
  )
}}

{% set yaml_metadata %}
hashkey: hk_entity_h
business_keys:
  - origin_system_bk
  - origin_system_entity_id
source_models:
  stage_entity_current_load:
    bk_columns:
      - origin_system
      - origin_system_entity_id
src_ldts: effective_from_date
src_rsrc: origin_system
additional_columns:
  - ingestion_id
  - ingestion_load_type
{% endset %}

with generated_hub as (
    {{ datavault4dbt.hub(yaml_metadata=yaml_metadata) }}
)

select
    ingestion_id,
    effective_from_date,
    ingestion_load_type,
    origin_system_bk as origin_system,
    origin_system_entity_id,
    hk_entity_h
from generated_hub
