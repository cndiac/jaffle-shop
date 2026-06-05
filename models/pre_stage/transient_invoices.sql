-- this will likely read data from a client source model
-- e.g. from a `stg_invoices` model built in a client's dbt project, like netsuite

-- also, this will contain ONLY the data pertaining to the current ingestion run,
-- so no need for any incremental filtering logic here
select
    'test' as origin_system,
    '{{ var('ingestion_id') }}' as ingestion_id,
    current_timestamp() as ingestion_timestamp
