#!/usr/bin/env bash
# Gitsim availability and basic behavior tests (harnessed).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Gitsim Environment"

# Require gitsim to be installed and available
if ! command -v gitsim >/dev/null 2>&1; then
  echo "gitsim is required for tests; not found in PATH" >&2
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

# --- Configuration and Helpers ---
# (Helpers are the same)
# Colors for output
readonly red=$'\x1B[38;5;197m'
readonly green=$'\x1B[32m'
readonly blue=$'\x1B[36m'
readonly orange=$'\x1B[38;5;214m'
readonly x=$'\x1B[0m'
# Glyphs
readonly pass_glyph="${green}✓${x}"
readonly fail_glyph="${red}✗${x}"
# Test state
test_count=0
failed_tests=()
# Helper to print a pass message
pass() {
    local test_name="$1"
    printf "  ${pass_glyph} PASS: %s\n" "$test_name"
}
# Helper to print a fail message
fail() {
    local test_name="$1"
    local reason="$2"
    printf "  ${fail_glyph} FAIL: %s\n" "$test_name"
    if [[ -n "$reason" ]]; then
        printf "    Reason: %s\n" "$reason"
    fi
    failed_tests+=("$test_name")
}
# The core test runner
run_test() {
    local test_name="$1"
    local cmd="$2"
    local expected_exit_code="${3:-0}"

    ((test_count++))
    printf "\n${blue}Running Test #%d: %s${x}\n" "$test_count" "$test_name"

    output=$(eval "$cmd" 2>&1)
    local exit_code=$?

    if [[ "$exit_code" -eq "$expected_exit_code" ]]; then
        pass "$test_name"
    else
        fail "$test_name" "Expected exit code $expected_exit_code, but got $exit_code."
        printf "    Command: %s\n" "$cmd"
        printf "    Output:\n%s\n" "$output"
    fi
}

# --- Test Environment ---
SIM_TEST_DIR="sim_test"

setup() {
    echo "Setting up simulator test environment in ./${SIM_TEST_DIR}..."
    rm -rf "$SIM_TEST_DIR"
    mkdir -p "$SIM_TEST_DIR"
    cp "git_sim.sh" "$SIM_TEST_DIR/"
    cd "$SIM_TEST_DIR" || exit 1
    chmod +x "git_sim.sh"
}

cleanup() {
    echo "Cleaning up simulator test environment..."
    cd ..
    rm -rf "$SIM_TEST_DIR"
}

# --- Main Test Execution ---
# Basic gitsim commands (adjust to canonical API as needed)
TMPDIR="$(fx_tmp_dir gitsim)"
pushd "$TMPDIR" >/dev/null

if assert_exit 0 "gitsim home-init"; then test_pass "home-init"; else test_fail "home-init"; fi
if assert_exit 0 "gitsim home-path"; then test_pass "home-path"; else test_fail "home-path"; fi

popd >/dev/null
fx_clean_tmp gitsim

test_end
