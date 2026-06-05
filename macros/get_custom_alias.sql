{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if 'transient_' in node.name and node.resource_type == 'model' -%}

        {{ node.name ~ '__' ~ var('ingestion_id') }}

    {%- elif custom_alias_name -%}

        {{ custom_alias_name | trim }}

    {%- else -%}

        {{ node.name }}

    {%- endif -%}

{%- endmacro %}
