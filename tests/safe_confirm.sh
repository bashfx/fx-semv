#!/usr/bin/env bash
# Safe confirm behavior test (SEMV_SAFE_CONFIRM=1)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Safe Confirm"

SEMV="$PROJECT_ROOT/semv.sh"

# Positive case: type 'yes' to confirm stable promotion
R1="$(fx_tmp_dir safe_confirm_yes)"
pushd "$R1" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo x > f && git add f && git commit -qm "feat: init"
git tag -a v0.1.0 -m baseline >/dev/null 2>&1 || true
if printf "yes\n" | SEMV_SAFE_CONFIRM=1 "$SEMV" --no-auto promote stable v0.1.0; then
  test_pass "safe confirm accepted 'yes'"
else
  test_fail "safe confirm rejected 'yes'"
fi
popd >/dev/null
fx_clean_tmp safe_confirm_yes

# Negative case: type 'no' to cancel
R2="$(fx_tmp_dir safe_confirm_no)"
pushd "$R2" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo x > f && git add f && git commit -qm "feat: init"
git tag -a v0.1.0 -m baseline >/dev/null 2>&1 || true
if printf "no\n" | SEMV_SAFE_CONFIRM=1 "$SEMV" --no-auto promote stable v0.1.0; then
  test_fail "safe confirm accepted 'no'"
else
  test_pass "safe confirm rejected 'no'"
fi
popd >/dev/null
fx_clean_tmp safe_confirm_no

test_end

