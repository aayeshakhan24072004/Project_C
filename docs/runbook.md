# Execution and Evidence Runbook

All destructive data demonstrations belong in a disposable GCP project/dataset. Replace `YOUR_GCP_PROJECT_ID` and use the profile target `dev`. Do not perform mutation demos in SIT/PROD.

## Layers and Materializations

| Layer | Models | Materialization |
| --- | --- | --- |
| Staging | `stg_*` | Views; lightweight typed projections |
| Intermediate | `int_account_transactions` | Ephemeral reusable transaction/account join |
| Intermediate | `int_customer_activity`, `int_loan_summary` | Tables by adapter default/configuration |
| Dimensions | `dim_*` | Tables |
| Facts | `fact_transactions` | Merge incremental, unique key `transaction_id` |
| Facts | `fact_loan_payments` | Table |
| Marts | `mart_*` | Tables |
| Marts | `mart_monthly_transaction_mv` | BigQuery materialized view example |

The materialized view is appropriate for frequently queried monthly summaries when BigQuery can incrementally maintain the aggregate. BigQuery's materialized-view SQL restrictions, base-table changes, refresh quotas, and adapter support apply. If the current adapter/API rejects this configuration, retain the model as a documented example and report the actual platform limitation; do not claim that it was deployed.

## Incremental Merge Demonstration

First clone only the raw tables needed by the transaction fact into a disposable source dataset. BigQuery table clones avoid rewriting the full CSVs:

```sql
CREATE SCHEMA IF NOT EXISTS `YOUR_GCP_PROJECT_ID.banksphere_raw_demo`;
CREATE OR REPLACE TABLE `YOUR_GCP_PROJECT_ID.banksphere_raw_demo.accounts`
  CLONE `YOUR_GCP_PROJECT_ID.banksphere_raw.accounts`;
CREATE OR REPLACE TABLE `YOUR_GCP_PROJECT_ID.banksphere_raw_demo.transactions`
  CLONE `YOUR_GCP_PROJECT_ID.banksphere_raw.transactions`;
```

Seed the model dependencies, then record the initial fact count:

```powershell
dbt seed --target dev
dbt build --select +fact_transactions --full-refresh --vars '{"raw_schema":"banksphere_raw_demo"}' --target dev
```

In BigQuery, insert one new event by copying valid account/customer keys from an existing event:

```sql
INSERT INTO `YOUR_GCP_PROJECT_ID.banksphere_raw_demo.transactions`
  (transaction_id, account_id, customer_id, transaction_date, transaction_type,
   channel, amount, currency, transaction_status, reference_number, description, updated_at)
SELECT
  CONCAT('TDEMO', SUBSTR(transaction_id, 2)), account_id, customer_id, CURRENT_DATE(),
  transaction_type, channel, 123.45, currency, 'SUCCESS',
  CONCAT('REFDEMO', SUBSTR(reference_number, 4)), 'Incremental demonstration', CURRENT_TIMESTAMP()
FROM `YOUR_GCP_PROJECT_ID.banksphere_raw_demo.transactions`
WHERE transaction_status = 'SUCCESS'
LIMIT 1;
```

Run only the incremental fact. The `is_incremental()` predicate now selects rows whose `source_updated_at` is within the configured three-day lookback of the current maximum; the merge updates the existing key or inserts the new key.

```powershell
dbt run --select fact_transactions --vars '{"raw_schema":"banksphere_raw_demo"}' --target dev
```

Update a recent source record, setting its `updated_at` to the current timestamp, run the fact again, and confirm the fact's row count is unchanged while its amount/status reflects the source update. Confirm the inserted ID exists once. Compare each run's bytes processed in BigQuery Job History or `INFORMATION_SCHEMA.JOBS_BY_PROJECT`; save job IDs, processed bytes, row counts, and the `dbt` log as evidence. Remove the demo dataset after evidence capture.

`merge` is selected because transaction events can be corrected and late-arriving changes should update by business key. `insert_overwrite` can be cheaper for complete date partitions but requires reliable partition replacement and late-data backfills. `microbatch` can bound work into event-time windows where the adapter supports it, but late corrections require an explicit lookback/backfill policy. These are design comparisons; only `merge` is implemented here.

The model uses `transaction_date` partitioning for date-range pruning and clusters by `account_id`, `customer_id`, and `transaction_type` for common predicates. Compare the full scan and date-filtered projection in `analyses/partition_pruning_comparison.sql`. Record bytes processed and slot/time observations; actual savings depend on table size, partition distribution, and BigQuery billing mode.

## History and Seeds

Run `dbt snapshot --target dev` once to establish baselines. Change `customer_segment` and `updated_at` for a customer in a disposable source, then run the snapshot again. Check the snapshot's `dbt_valid_from`, `dbt_valid_to`, and `dbt_scd_id` fields to see the prior version closed and new version opened. For accounts, change `account_status` (or another configured `check_cols`) and repeat. Remove a row and rerun to demonstrate `hard_deletes='invalidate'`; hard-delete support requires dbt Core 1.9+ and the adapter's compatible snapshot strategy. Timestamp strategy depends on a reliable, monotonically advancing `source_updated_at`; check strategy compares selected values.

The snapshots are stored in the environment-specific `*_snapshots` dataset. dbt-managed metadata includes `dbt_scd_id`, `dbt_valid_from`, `dbt_valid_to`, and strategy-specific update/check fields. `banking_reference_codes.csv` has ten stable, low-change product mappings and is appropriate for `dbt seed`; large, frequently refreshed operational extracts remain raw BigQuery sources, not seeds.

## Test-Failure Demonstrations

Use a disposable dataset and capture the failing test output, diagnose the key, fix the source row, and rerun the same test:

1. Duplicate key: append a duplicate `account_id` to the demo accounts table and run `dbt test --select source:banksphere_raw.accounts`; expect the source uniqueness test to fail.
2. Relationship: append an account with a nonexistent `customer_id`; run `dbt test --select stg_accounts`; trace the failing `customer_id`, fix it to a valid customer, and rerun.
3. Broken source reference: temporarily misspell a source table in a development branch, then run `dbt compile`; the source resolution error should identify the missing source/table. Restore the declared name and compile again.
4. Incremental filter: temporarily replace the lookback predicate with an incorrect event-date-only predicate, update a previously loaded source event outside the event-date window, and observe the stale fact. Restore the `source_updated_at` filter, rerun, and verify merge correction.
5. Schema change: add a column to the demo raw table and then explicitly project it from staging/fact SQL. With `on_schema_change='append_new_columns'`, the incremental destination adds the selected field; unselected raw columns are intentionally ignored.
6. Business rules: the singular tests cover negative successful amounts, transaction/account customer mismatch, and outstanding loan amounts above sanctioned amounts. The local validator reports equivalent defects before cloud loading.

The account-status accepted-values test is configured with `severity: warn` to surface unexpected states without immediately blocking a run; key, relationship, and critical business-rule tests remain errors. Fix source data or model logic rather than weakening those assertions to obtain a green build.

## Freshness, Docs, and Exposure

`accounts`, `customers`, and `transactions` freshness use `updated_at` as the supplied extract's freshness proxy (warn after 24 hours, error after 72). This is not a true ingestion watermark. A stale/error result should page or block downstream processing until upstream delivery is confirmed. The static provided data is historical relative to the assignment date, so a healthy live-freshness result cannot be shown until a new extract is loaded.

Generate docs with `dbt docs generate`; inspect the DAG for `source -> stg -> int/dim/fact -> mart`. The Executive Banking Dashboard exposure selects with:

```powershell
dbt ls --select exposure:executive_banking_dashboard --target dev
```

## BigQuery, Environments, and Hooks

BigQuery project is the cloud resource/security namespace. Dataset is a BigQuery schema. In dbt, `target.database` maps to the project and `target.schema` maps to the profile's environment dataset. The custom schema macro appends logical layers, for example `banksphere_dev_core` and `banksphere_dev_marts`; raw remains `banksphere_raw`.

The project-level run hooks emit invocation-tagged log events; fact pre/post hooks issue lightweight `SELECT CURRENT_TIMESTAMP()` audit records to BigQuery job history. They do not mutate business tables or create unbounded audit storage. Review hook SQL before production: a hook that scans or changes a large table can add cost or cause data loss.

Promote the same commit and project configuration by running `dbt build --target dev`, then `--target sit`, then `--target prod` after approval. Keep credentials and `profiles.yml` outside Git. Configure GitHub as dbt Cloud's project repository, use secure BigQuery OAuth/service-account configuration in dbt Cloud, define Development/SIT/Production deployment environments, and create a production `dbt build` job with schedules and alerts. These account-bound actions and run logs must be completed in the participant's own services.

## Packages and Performance Evidence

`dbt_utils.date_spine` is used for `dim_date`; dependency version is managed in `packages.yml` and materialized under ignored `dbt_packages/`. `dbt deps` installs the declared version range. The dependency is reproducible from the project file; do not commit installed package internals.

Three costly query patterns to identify are unfiltered scans of the transaction fact, `SELECT *` in dashboards, and joining raw transactions to unaggregated accounts/cards/loans before summing (fanout). This project addresses the first two with partitioning and explicit projections and avoids fanout in customer/branch marts by aggregating each subject first. Use BigQuery job history to compare bytes and latency before/after on the same data and parameters; no cloud metrics are claimed until measured.

## Dagster Run Evidence

Set `DBT_TARGET=dev`, start `dagster dev -m orchestration.definitions`, run `banksphere_daily_job`, and capture the successful run and enabled `banksphere_daily_0230_utc` schedule. Run `banksphere_failed_run_demo` to capture the expected intentional failure; it does not alter data. A failed dbt op also fails the Dagster run and preserves subprocess output in its logs.