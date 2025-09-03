#!/usr/bin/env bash
# 001 - Status data and view integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/tests/lib/ceremony.sh"
source "$ROOT_DIR/tests/lib/assert.sh"
source "$ROOT_DIR/tests/lib/env.sh"

SEMV="$ROOT_DIR/semv.sh"
WORK_DIR="$(fx_tmp_dir uat001_status)"

cleanup() { fx_clean_tmp uat001_status; }
trap cleanup EXIT

# Arrange: init repo with a commit and a version header file
pushd "$WORK_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo "# semv-version: 0.1.0" > app.sh
git add app.sh
git commit -qm "feat: init"

# Act + Assert: data mode returns kv pairs with required keys
out="$($SEMV status --view=data)"
echo "$out" | grep -q 'user='
echo "$out" | grep -q 'repo='
echo "$out" | grep -q 'changes='
echo "$out" | grep -q 'version_current='
echo "$out" | grep -q 'pkg='

# Human view renders without error
assert_exit 0 "$SEMV status"

popd >/dev/null
exit 0

