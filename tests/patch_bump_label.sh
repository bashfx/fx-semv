#!/usr/bin/env bash
# Patch bump label test: a fix: commit should yield v0.1.1 from v0.1.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Patch Bump Label"

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
R="$(fx_tmp_dir patch_bump_repo)"

pushd "$R" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

echo x > f
git add f
git commit -qm "feat: init"
git tag -a v0.1.0 -m baseline >/dev/null 2>&1 || true

# Add a fix commit
echo y >> f
git add f
git commit -qm "fix: correct minor issue"

# Allow trace lines; match presence of v0.1.1 anywhere
if assert_match "v0\.1\.1" "$SEMV next"; then
  test_pass "next is patch bump"
else
  test_fail "next did not produce patch bump"
fi

popd >/dev/null
fx_clean_tmp patch_bump_repo

test_end
