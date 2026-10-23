{{
  config(
    enabled=(var('load_type', 'FULL') | upper) == 'FULL',
    materialized=var('rdv_materialization', 'incremental'),
    incremental_strategy='append'
  )
}}

{% set yaml_metadata %}
source_model: stage_entity_current_load
tracked_hashkey: hk_entity_h
src_ldts: effective_from_date
src_rsrc: origin_system
is_active_alias: is_active
source_is_single_batch: {{ var('source_is_single_batch', true) | lower }}
additional_columns:
  - ingestion_id
  - ingestion_load_type
{% endset %}

with generated_effectivity_satellite as (
    {% if var('use_partitioned_eff_sat', false) %}
    {{
      dv4dbt_partitioned_eff_sat_v0(
        source_model='stage_entity_current_load',
        tracked_hashkey='hk_entity_h',
        partition_by=var('eff_sat_partition_by', 'origin_system'),
        src_ldts='effective_from_date',
        ingestion_id_column='ingestion_id',
        ingestion_load_type_column='ingestion_load_type'
      )
    }}
    {% else %}
    {{ datavault4dbt.eff_sat_v0(yaml_metadata=yaml_metadata) }}
    {% endif %}
)

select
    ingestion_id,
    effective_from_date,
    ingestion_load_type,
    origin_system,
    hk_entity_h,
    is_active
from generated_effectivity_satellite
