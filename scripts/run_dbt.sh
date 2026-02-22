#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/dbt"

echo "[run_dbt] dbt deps"
dbt deps

echo "[run_dbt] dbt run"
dbt run

echo "[run_dbt] dbt test"
dbt test
