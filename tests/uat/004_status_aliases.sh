#!/usr/bin/env bash
# 004 - Status aliases and gs behavior
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT_DIR/tests/lib/ceremony.sh"
source "$ROOT_DIR/tests/lib/assert.sh"
source "$ROOT_DIR/tests/lib/env.sh"

SEMV="$ROOT_DIR/semv.sh"
WORK_DIR="$(fx_tmp_dir uat004_aliases)"

cleanup() { fx_clean_tmp uat004_aliases; }
trap cleanup EXIT

pushd "$WORK_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo "# semv-version: 0.1.0" > app.sh
git add app.sh
git commit -qm "feat: init"

# status and st should both exit 0 and render
assert_exit 0 "$SEMV status --view=data"
assert_exit 0 "$SEMV st --view=data"

# Create a change and verify gs returns a number > 0
echo x >> app.sh
out="$($SEMV gs)"
[[ "$out" =~ ^[0-9]+$ ]]
[[ "$out" -gt 0 ]]

popd >/dev/null
exit 0

