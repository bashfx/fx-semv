#!/usr/bin/env bash
# Quick SEMV functionality test (harnessed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "SEMV Quick Functionality"

if assert_match "USAGE" "./semv.sh help"; then test_pass "help"; else test_fail "help"; fi
# Allow trace lines before the version; match a version anywhere in output
if assert_match "v[0-9]+\.[0-9]+\.[0-9]+" "./semv.sh next"; then test_pass "next"; else test_fail "next"; fi
if assert_exit 0 "timeout 3 ./semv.sh get all"; then test_pass "get all (timeout)"; else test_fail "get all"; fi
if assert_exit 0 "timeout 3 ./semv.sh info"; then test_pass "info (timeout)"; else test_fail "info"; fi

# Non-fatal exploratory
timeout 3 ./semv.sh sync >/dev/null 2>&1 || true

test_end
