#!/usr/bin/env bash
# Promote to release tests (resolved-commit tagging)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Promote to Release"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir promote_release_repo)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

echo "x" > f.txt
git add f.txt
git commit -qm "feat: init"

# Create a stable tag to promote
git tag -a v0.1.1 -m "stable"

# Promote specified stable version to release
if assert_exit 0 "$SEMV promote release v0.1.1 -y"; then test_pass "promote release"; else test_fail "promote release"; fi

# Release tag exists and points to the same commit as stable tag
STABLE_OBJ=$(git rev-list -n 1 v0.1.1 || true)
REL_OBJ=$(git rev-list -n 1 release || true)
if [[ -n "$STABLE_OBJ" && -n "$REL_OBJ" && "$STABLE_OBJ" == "$REL_OBJ" ]]; then
  test_pass "release points to stable commit"
else
  test_fail "release does not point to stable commit"
fi

popd >/dev/null
fx_clean_tmp promote_release_repo

test_end

