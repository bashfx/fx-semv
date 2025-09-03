#!/usr/bin/env bash
# 003 - Sync with source file authority (highest wins)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/tests/lib/ceremony.sh"
source "$ROOT_DIR/tests/lib/assert.sh"
source "$ROOT_DIR/tests/lib/env.sh"

SEMV="$ROOT_DIR/semv.sh"
WORK_DIR="$(fx_tmp_dir uat003_sync)"

cleanup() { fx_clean_tmp uat003_sync; }
trap cleanup EXIT

pushd "$WORK_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Case 1: No tags, file version becomes baseline
echo "# semv-version: 2.3.4" > meta.sh
git add meta.sh
git commit -qm "feat: add meta"
assert_exit 0 "$SEMV sync meta.sh --auto"
latest_tag="$(git tag | sort -V | tail -n1)"
[[ "$latest_tag" == "v2.3.4" ]]

# Case 2: Existing lower tag, file version higher becomes authority
git tag -a v2.3.5 -m "lower" || true
echo "# semv-version: 2.4.0" > meta.sh
git add meta.sh
git commit -qm "feat: bump meta"
assert_exit 0 "$SEMV sync meta.sh --auto"
latest_tag="$(git tag | sort -V | tail -n1)"
[[ "$latest_tag" == "v2.4.0" ]]

popd >/dev/null
exit 0

