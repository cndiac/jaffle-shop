{% macro dv4dbt_partitioned_eff_sat_v0(
    source_model,
    tracked_hashkey,
    partition_by,
    src_ldts,
    ingestion_id_column,
    ingestion_load_type_column,
    is_deleted_column
) %}

with source_data as (
    select
        {{ tracked_hashkey }},
        {{ ingestion_id_column }},
        {{ src_ldts }},
        {{ ingestion_load_type_column }},
        {{ partition_by }},
        {{ is_deleted_column }}
    from {{ ref(source_model) }}
    qualify row_number() over (
        partition by {{ partition_by }}, {{ tracked_hashkey }}
        order by {{ src_ldts }} desc
    ) = 1
),

batch_metadata as (
    select
        {{ partition_by }},
        max({{ ingestion_id_column }}) as {{ ingestion_id_column }},
        max({{ src_ldts }}) as {{ src_ldts }},
        max({{ ingestion_load_type_column }}) as {{ ingestion_load_type_column }}
    from source_data
    group by {{ partition_by }}
),

{% if is_incremental() %}
current_status as (
    select
        target.{{ tracked_hashkey }},
        target.{{ partition_by }},
        target.is_active
    from {{ this }} as target
    where exists (
        select 1
        from batch_metadata
        where batch_metadata.{{ partition_by }} = target.{{ partition_by }}
    )
    qualify row_number() over (
        partition by target.{{ partition_by }}, target.{{ tracked_hashkey }}
        order by target.{{ src_ldts }} desc
    ) = 1
),
{% endif %}

source_status_changes as (
    select
        source.{{ ingestion_id_column }},
        source.{{ src_ldts }},
        source.{{ ingestion_load_type_column }},
        source.{{ partition_by }},
        source.{{ tracked_hashkey }},
        cast(
            not coalesce(source.{{ is_deleted_column }}, false)
            as boolean
        ) as is_active
    from source_data as source
    {% if is_incremental() %}
    left join current_status as current_state
        on current_state.{{ partition_by }} = source.{{ partition_by }}
        and current_state.{{ tracked_hashkey }} = source.{{ tracked_hashkey }}
    where current_state.{{ tracked_hashkey }} is null
       or current_state.is_active != cast(
           not coalesce(source.{{ is_deleted_column }}, false)
           as boolean
       )
    {% endif %}
),

{% if is_incremental() %}
disappeared_hashkeys as (
    select
        batch.{{ ingestion_id_column }},
        batch.{{ src_ldts }},
        batch.{{ ingestion_load_type_column }},
        current_state.{{ partition_by }},
        current_state.{{ tracked_hashkey }},
        cast(false as boolean) as is_active
    from current_status as current_state
    join batch_metadata as batch
        on batch.{{ partition_by }} = current_state.{{ partition_by }}
    where upper(batch.{{ ingestion_load_type_column }}) = 'FULL'
      and current_state.is_active = true
      and not exists (
          select 1
          from source_data as source
          where source.{{ partition_by }} = current_state.{{ partition_by }}
            and source.{{ tracked_hashkey }} = current_state.{{ tracked_hashkey }}
      )
),
{% endif %}

records_to_insert as (
    select * from source_status_changes
    {% if is_incremental() %}
    union all
    select * from disappeared_hashkeys
    {% endif %}
)

select *
from records_to_insert as incoming
{% if is_incremental() %}
where not exists (
    select 1
    from {{ this }} as existing
    where existing.{{ tracked_hashkey }} = incoming.{{ tracked_hashkey }}
      and existing.{{ src_ldts }} = incoming.{{ src_ldts }}
)
{% endif %}

{% endmacro %}
