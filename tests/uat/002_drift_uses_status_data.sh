#!/usr/bin/env bash
# 002 - Drift command uses status_data and detects drift
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/tests/lib/ceremony.sh"
source "$ROOT_DIR/tests/lib/assert.sh"
source "$ROOT_DIR/tests/lib/env.sh"

SEMV="$ROOT_DIR/semv.sh"
WORK_DIR="$(fx_tmp_dir uat002_drift)"

cleanup() { fx_clean_tmp uat002_drift; }
trap cleanup EXIT

pushd "$WORK_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo "# semv-version: 1.2.0" > app.sh
git add app.sh
git commit -qm "feat: init"
git tag -a v1.0.0 -m "baseline"

# Drift should be detected (pkg 1.2.0 vs git v1.0.0)
assert_exit 0 "$SEMV drift"

# --view=data prints the status_data stream; ensure it includes pkg and git
data_line="$($SEMV drift --view=data)"
echo "$data_line" | grep -q 'pkg=1.2.0'
echo "$data_line" | grep -q 'git=v1.0.0'

popd >/dev/null
exit 0

