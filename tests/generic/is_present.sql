{% test is_present(model, column_name) %}
    {% if execute %}
        {%- set model_name = model.name -%}
        {%- set model_version_match = modules.re.search('_v([0-9]+([._][0-9]+|_[0-9]+)*)', model_name) -%}

        {%- if model_version_match -%}
            {%- set model_version = model_version_match.group() | replace('_', '.') -%}
        {%- else -%}
            {%- set model_version = '' -%}
        {%- endif -%}
        {%- set model_graph_ref = 'model.' ~ project_name ~ '.' ~ modules.re.sub('_v([0-9]+([._][0-9]+|_[0-9]+)*)', model_version|trim, model_name) -%}
        {{ log("Model graph ref: " ~ model_graph_ref, info=True) }}
        {%- if column_name -%}
            {%- set column_config = graph.get("nodes")[model_graph_ref]['columns'].get(column_name, {}) -%}
            {{ log("Column Config: " ~ column_config, info=True) }}
            {%- set column_meta = column_config.get("meta", {}) -%}
            {{ log("Column Meta: " ~ column_meta, info=True) }}
            {%- set artifact_component = column_meta.get("artifact_component", none) -%}
            {{ log("Artifact Component: " ~ artifact_component, info=True) }}
        {%- else -%}
            {%- set artifact_component = none -%}
        {%- endif -%}
    {% else %}
        {% set artifact_component = none %}
    {%- endif -%}

    {{ log("Artifact component: " ~ artifact_component|string, info=True) }}

  select *
  from {{ model }}
  where {{ column_name }} is null

{% endtest %}
