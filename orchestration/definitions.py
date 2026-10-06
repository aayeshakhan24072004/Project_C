import os
import subprocess
import sys
from pathlib import Path

from dagster import Definitions, Failure, ScheduleDefinition, job, op


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DBT_TARGET = os.getenv("DBT_TARGET", "dev")


def run_dbt(context, *arguments):
    command = ["dbt", *arguments, "--target", DBT_TARGET]
    context.log.info("Running: " + " ".join(command))
    result = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    context.log.info(result.stdout)
    if result.stderr:
        context.log.warning(result.stderr)
    if result.returncode:
        raise Failure(f"dbt command failed with exit code {result.returncode}")


@op
def validate_source_csvs():
    result = subprocess.run(
        [sys.executable, "scripts/validate_source_csvs.py"],
        cwd=PROJECT_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.stdout:
        print(result.stdout)
    if result.returncode:
        raise Failure("Local raw-file quality gate failed")


@op
def dbt_staging(context, raw_files_validated):
    run_dbt(context, "build", "--select", "path:models/staging")


@op
def dbt_core(context, staging_built):
    run_dbt(
        context,
        "build",
        "--select",
        "path:models/intermediate",
        "path:models/dimensions",
        "path:models/facts",
    )


@op
def dbt_marts(context, core_built):
    run_dbt(context, "build", "--select", "path:models/marts")


@op
def dbt_full_quality_gate(context, marts_built):
    run_dbt(context, "test")


@job
def banksphere_daily_job():
    raw_files_validated = validate_source_csvs()
    staging_built = dbt_staging(raw_files_validated)
    core_built = dbt_core(staging_built)
    marts_built = dbt_marts(core_built)
    dbt_full_quality_gate(marts_built)


@op
def intentional_failure_demo():
    raise Failure("Intentional Dagster failure demonstration; no data was modified.")


@job
def banksphere_failed_run_demo():
    intentional_failure_demo()


daily_schedule = ScheduleDefinition(
    job=banksphere_daily_job,
    cron_schedule="30 2 * * *",
    execution_timezone="UTC",
    name="banksphere_daily_0230_utc",
)

defs = Definitions(
    jobs=[banksphere_daily_job, banksphere_failed_run_demo],
    schedules=[daily_schedule],
)