#!/usr/bin/env bash
# Promote to beta tests (resolved-commit tagging)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Promote to Beta"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir promote_beta_repo)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

echo "x" > f.txt
git add f.txt
git commit -qm "feat: init"

# Create a dev tag to promote from
git tag -a v0.1.1-dev_1 -m "dev state"

# Promote specified dev version to beta
if assert_exit 0 "$SEMV promote beta v0.1.1-dev_1 -y"; then test_pass "promote beta"; else test_fail "promote beta"; fi

# Beta tag exists and points to the same commit as dev tag
DEV_OBJ=$(git rev-list -n 1 v0.1.1-dev_1 || true)
BETA_OBJ=$(git rev-list -n 1 v0.1.1-beta || true)
if [[ -n "$DEV_OBJ" && -n "$BETA_OBJ" && "$DEV_OBJ" == "$BETA_OBJ" ]]; then
  test_pass "beta points to dev commit"
else
  test_fail "beta does not point to dev commit"
fi

popd >/dev/null
fx_clean_tmp promote_beta_repo

test_end

