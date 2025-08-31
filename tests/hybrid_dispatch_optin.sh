#!/usr/bin/env bash
# Hybrid dispatcher opt-in test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Hybrid Dispatch Opt-in"

SEMV="$PROJECT_ROOT/semv.sh"

# Without hybrid flag, unknown command should fail
if assert_exit 1 "$SEMV install-status"; then
  test_pass "invalid without hybrid"
else
  test_fail "unexpectedly valid without hybrid"
fi

# With hybrid flag, derived mapping should work
if assert_exit 0 "SEMV_FEATURE_HYBRID=1 $SEMV install-status"; then
  test_pass "valid with hybrid"
else
  test_fail "failed with hybrid enabled"
fi

test_end

