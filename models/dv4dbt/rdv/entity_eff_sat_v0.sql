{{
  config(
    enabled=(var('entity_ingestion_load_type', 'FULL') | upper) == 'FULL',
    materialized=var('entity_rdv_materialization', 'incremental'),
    incremental_strategy='append'
  )
}}

{% set yaml_metadata %}
source_model: entity_current_ingestion
tracked_hashkey: hk_entity_h
src_ldts: ldts
src_rsrc: rsrc
is_active_alias: is_active
source_is_single_batch: {{ var('entity_source_is_single_batch', true) | lower }}
additional_columns:
  - ingestion_id
  - origin_system
  - ingestion_load_type
{% endset %}

{{ datavault4dbt.eff_sat_v0(yaml_metadata=yaml_metadata) }}
