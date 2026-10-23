Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

## datavault4dbt entity experiment

The models under `models/dv4dbt` provide a small Snowflake
experiment with configurable scenario seeds, a persisted stage, a standard RDV
Satellite, and an Effectivity Satellite.

Load the scenario seeds first:

```sh
dbt seed --select path:seeds/dv4dbt
```

Select one scenario seed with `source_model`. Scenario 1 processes
three successive full snapshots. Run each command separately so
`effective_from_date` records a distinct technical ingestion time:

```sh
dbt build --select +tag:dv4dbt --vars \
  '{ingestion_id: scenario1a, source_model: scenario1a, load_type: FULL, stage_entity_materialization: incremental, rdv_materialization: incremental}'

dbt build --select +tag:dv4dbt --vars \
  '{ingestion_id: scenario1b, source_model: scenario1b, load_type: FULL, stage_entity_materialization: incremental, rdv_materialization: incremental}'

dbt build --select +tag:dv4dbt --vars \
  '{ingestion_id: scenario1c, source_model: scenario1c, load_type: FULL, stage_entity_materialization: incremental, rdv_materialization: incremental}'
```

Entity `1003` is present in `scenario1a` and absent from `scenario1b`, allowing
the Effectivity Satellite to infer its disappearance. Entity `1002` remains
present as an explicit `is_deleted=true` tombstone in `scenario1b`, allowing the
standard Satellite behavior to be compared with effectivity behavior. The
standard Satellite also receives a reconfirmation row for each new
`current_as_of_date`, because that column is part of `hd_entity_s`.

`ingestion_id` and `load_type` are run variables rather than
CSV fields. Both are persisted in the stage and RDV Satellite. The RDV models
read `stage_entity_current_load`, which filters `stage_entity` to the
current `ingestion_id` and calculates the hashkey and hashdiff. The persisted
`stage_entity` remains unhashed. The Effectivity Satellite is enabled only for
`FULL`; DELTA rows continue into the standard Satellite, where explicit
`is_deleted` tombstones are preserved.

`stage_entity_materialization` and `rdv_materialization` accept `table`
to recreate their relations or `incremental` to retain and append history. An
Effectivity Satellite processing one snapshot at a time must remain incremental
to compare the new snapshot with its previous state. Set
`source_is_single_batch: false` only when one execution reads several
complete snapshot timestamps; it does not partition independently arriving
providers.

### Partition-aware Effectivity experiment

`use_partitioned_eff_sat` chooses the Effectivity implementation:

- `false`: standard `datavault4dbt.eff_sat_v0` behavior.
- `true`: local override that scopes comparisons to the `origin_system`
  partitions present in the current ingestion.

Start the partition-aware test from a clean Effectivity Satellite:

```sh
dbt build --select +tag:dv4dbt --full-refresh --vars \
  '{ingestion_id: 1, source_model: scenario1a, load_type: FULL, stage_entity_materialization: incremental, rdv_materialization: incremental, use_partitioned_eff_sat: true}'
```

Then ingest a different provider without refreshing:

```sh
dbt build --select +tag:dv4dbt --vars \
  '{ingestion_id: 2, source_model: scenario2a, load_type: FULL, stage_entity_materialization: incremental, rdv_materialization: incremental, use_partitioned_eff_sat: true}'
```

Provider Alpha remains unchanged during the Provider Beta load. Setting the
toggle to `false` reproduces the stock cross-provider deactivation behavior.
