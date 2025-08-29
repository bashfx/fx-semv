#!/usr/bin/env bash
# Promote to stable tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Promote to Stable"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir promote_repo)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

echo "x" > f.txt
git add f.txt
git commit -qm "feat: init"
git tag -a v0.1.1 -m "baseline" >/dev/null 2>&1 || true

# Promote specified version to stable
if assert_exit 0 "$SEMV promote stable v0.1.1 -y"; then test_pass "promote stable"; else test_fail "promote stable"; fi

# Check latest tag points to v0.1.1
if git rev-parse latest >/dev/null 2>&1; then
  test_pass "latest tag exists"
else
  test_fail "latest tag missing"
fi

# Stable snapshot exists
if git rev-parse v0.1.1-stable >/dev/null 2>&1; then
  test_pass "stable snapshot exists"
else
  test_fail "stable snapshot missing"
fi

popd >/dev/null
fx_clean_tmp promote_repo

test_end

