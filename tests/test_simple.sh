#!/usr/bin/env bash
# Simple SEMV testing (BashFX ceremony pattern)

set -euo pipefail

# semv-version: 1.0.0

# Load test libs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

NAME="simple"
test_start "SEMV Simple Test"

# Basic commands
if assert_exit 0 "./semv.sh help"; then test_pass "help"; else test_fail "help"; fi
if assert_exit 0 "./semv.sh next"; then test_pass "next"; else test_fail "next"; fi

# get bash for this file should return our version
if assert_match "1\\.0\\.0" "./semv.sh get bash $SCRIPT_DIR/test_simple.sh"; then
  test_pass "get bash"
else
  test_fail "get bash"
fi

if assert_exit 0 "./semv.sh get all"; then test_pass "get all"; else test_fail "get all"; fi

test_end
