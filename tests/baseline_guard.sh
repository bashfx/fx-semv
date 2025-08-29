#!/usr/bin/env bash
# Baseline guard tests for bump/promote

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Baseline Guard"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir guard_repo)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

echo "x" > f.txt
git add f.txt
git commit -qm "feat: init"

# No tags present; bump should be guarded
if assert_exit 1 "$SEMV bump"; then test_pass "bump guarded"; else test_fail "bump not guarded"; fi
# Promote should be guarded
if assert_exit 1 "$SEMV promote stable v0.1.0"; then test_pass "promote guarded"; else test_fail "promote not guarded"; fi

popd >/dev/null
fx_clean_tmp guard_repo

test_end

