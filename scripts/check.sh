#!/usr/bin/env bash
# The gate: tools/oracle.py (Python) and CASES (the Mojo runner from tests/cases.mojo)
# print the same lines for the same fixed inputs.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CASES:?FAIL setup: set CASES to the built case runner}"
mkdir -p .work
python3 -I tools/oracle.py > .work/exp.txt
timeout 60 "$CASES" > .work/got.txt || { echo "FAIL run: runner exited non-zero"; exit 1; }
diff .work/exp.txt .work/got.txt > .work/diff.txt || { echo "FAIL check: $(grep -c '^<' .work/diff.txt) line(s) differ from Python"; head -10 .work/diff.txt; exit 1; }
echo "cases: $(wc -l < .work/exp.txt)"
echo "PASS all"
