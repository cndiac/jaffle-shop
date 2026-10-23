{{
  config(
    materialized=var('entity_rdv_materialization', 'incremental'),
    incremental_strategy='append'
  )
}}

{% set yaml_metadata %}
parent_hashkey: hk_entity_h
src_hashdiff: hd_entity_s
src_payload:
  - is_deleted
  - current_as_of_date
  - origin_system
  - origin_system_entity_id
  - entity_name
source_model: entity_current_ingestion
src_ldts: ldts
src_rsrc: rsrc
source_is_single_batch: {{ var('entity_source_is_single_batch', true) | lower }}
additional_columns:
  - ingestion_id
  - ingestion_load_type
{% endset %}

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}
