#!/usr/bin/env python3
"""Run the partition-aware Data Vault scenario one ingestion at a time."""

from __future__ import annotations

import json
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DBT_RUNS: tuple[dict[str, Any], ...] = (
    {
        "full_refresh": True,
        "vars": {
            "ingestion_id": 1,
            "source_model": "scenario2a",
            "load_type": "FULL",
            "use_partitioned_eff_sat": True,
        },
    },
    {
        "full_refresh": False,
        "vars": {
            "ingestion_id": 2,
            "source_model": "scenario2b",
            "load_type": "FULL",
            "use_partitioned_eff_sat": True,
        },
    },
    {
        "full_refresh": False,
        "vars": {
            "ingestion_id": 3,
            "source_model": "scenario2c",
            "load_type": "FULL",
            "use_partitioned_eff_sat": True,
        },
    },
)


def build_command(run: dict[str, Any]) -> list[str]:
    """Build the dbt command for one ingestion."""
    command = [
        "poetry",
        "run",
        "dbt",
        "build",
        "--select",
        "+tag:dv4dbt",
    ]
    if run["full_refresh"]:
        command.append("--full-refresh")
    command.extend(["--vars", json.dumps(run["vars"])])
    return command


def main() -> int:
    """Show and execute the configured ingestion sequence interactively."""
    print("Execution sequence:\n")
    for position, run in enumerate(DBT_RUNS, start=1):
        print(f"{position}. {shlex.join(build_command(run))}\n")

    for position, run in enumerate(DBT_RUNS, start=1):
        command = build_command(run)
        print(f"\nRunning {position}/{len(DBT_RUNS)}")
        print(shlex.join(command), flush=True)

        try:
            subprocess.run(command, cwd=PROJECT_ROOT, check=True)
        except subprocess.CalledProcessError as error:
            print(
                f"\nRun {position} failed with exit code {error.returncode}. "
                "The remaining runs were not started.",
                file=sys.stderr,
            )
            return error.returncode

        if position < len(DBT_RUNS):
            input(
                f"\nRun {position} completed. Inspect the data, then press Enter "
                "to continue..."
            )

    print("\nAll scenario runs completed successfully.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nStopped by user.", file=sys.stderr)
        raise SystemExit(130) from None
