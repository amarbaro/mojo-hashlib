#!/usr/bin/env bash
# CI entry point, same on a GitHub runner and a local Ubuntu VM: install, then the gate.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v uv >/dev/null || { echo "FAIL setup: uv not installed"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL setup: python3 (the oracle) not found"; exit 1; }
uv sync || { echo "FAIL setup: uv sync"; exit 1; }
python3 -c 'import sys; print("oracle python", sys.version.split()[0])'
mkdir -p .work
M=.venv/bin/mojo
$M build -I src tests/cases.mojo -o .work/cases || { echo "FAIL build: tests/cases.mojo"; exit 1; }
CASES=.work/cases scripts/check.sh
$M run -I src tests/api.mojo || { echo "FAIL api: tests/api.mojo"; exit 1; }
$M run -I src examples/quickstart.mojo > /dev/null || { echo "FAIL example: examples/quickstart.mojo"; exit 1; }
echo "PASS ci"
