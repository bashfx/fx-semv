#!/usr/bin/env bash
# Validate/Drift edge cases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Validate/Drift Edge Cases"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"

# Case 1: No tags, has package (aligned)
R1="$(fx_tmp_dir v_edge_1)"
pushd "$R1" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
printf "[package]\nname=\"edge\"\nversion=\"1.2.3\"\n" > Cargo.toml
git add Cargo.toml
git commit -qm "feat: add cargo"
if assert_exit 0 "$SEMV validate"; then test_pass "validate ok (no tags, has package)"; else test_fail "validate (no tags, has package)"; fi
if assert_exit 1 "$SEMV drift"; then test_pass "drift aligned (no tags, has package)"; else test_fail "drift aligned (no tags, has package)"; fi
popd >/dev/null
fx_clean_tmp v_edge_1

# Case 2: Tags only (no package)
R2="$(fx_tmp_dir v_edge_2)"
pushd "$R2" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo x > f
git add f
git commit -qm "feat: init"
git tag -a v0.4.0 -m "baseline" >/dev/null 2>&1 || true
if assert_exit 0 "$SEMV validate"; then test_pass "validate ok (tags only)"; else test_fail "validate (tags only)"; fi
if assert_exit 1 "$SEMV drift"; then test_pass "drift aligned (tags only)"; else test_fail "drift aligned (tags only)"; fi
popd >/dev/null
fx_clean_tmp v_edge_2

test_end

