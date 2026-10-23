{{ config(materialized='view') }}

{% set ingestion_id = var('ingestion_id', none) %}

{% if ingestion_id is none or ingestion_id | string | trim == '' %}
  {{ exceptions.raise_compiler_error('ingestion_id must be provided') }}
{% endif %}

select *
from {{ ref('entity_stage') }}
where ingestion_id = '{{ ingestion_id | string | replace("'", "''") }}'
