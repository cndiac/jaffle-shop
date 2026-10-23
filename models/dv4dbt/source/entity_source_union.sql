{{ config(materialized='view') }}

{% set source_models = var('entity_source_models', ['scenario1b']) %}
{% set ingestion_id = var('ingestion_id', none) %}
{% set ingestion_load_type = var('entity_ingestion_load_type', 'FULL') | upper %}

{% if source_models | length == 0 %}
  {{ exceptions.raise_compiler_error('entity_source_models must contain at least one seed model') }}
{% endif %}

{% if ingestion_id is none or ingestion_id | string | trim == '' %}
  {{ exceptions.raise_compiler_error('ingestion_id must be provided') }}
{% endif %}

{% if ingestion_load_type not in ['FULL', 'DELTA'] %}
  {{ exceptions.raise_compiler_error('entity_ingestion_load_type must be FULL or DELTA') }}
{% endif %}

{% for source_model in source_models %}
select
    '{{ ingestion_id | string | replace("'", "''") }}' as ingestion_id,
    '{{ ingestion_load_type }}' as ingestion_load_type,
    current_as_of_date,
    is_deleted,
    origin_system,
    origin_system_entity_id,
    entity_name
from {{ ref(source_model) }}
{% if not loop.last %}union all{% endif %}
{% endfor %}
