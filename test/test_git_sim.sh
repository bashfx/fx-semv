#!/usr/bin/env bash

# test_git_sim.sh - A test runner for the git_sim.sh script

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
main() {
    setup

    echo ""
    echo "--- Starting Git Simulator Test Suite ---"

    run_test "init: should create .gitsim directory" "./git_sim.sh init"
    run_test "init: .gitignore should be created" "[ -f .gitignore ]"

    run_test "config: set user.name" "./git_sim.sh config user.name 'Test Sim User'"

    run_test "tag: creating a tag with no commit should fail" "! ./git_sim.sh tag -a v0.0.1 -m 'fail'"

    run_test "commit: make a first commit" "./git_sim.sh commit -m 'feat: first' --allow-empty"

    run_test "tag: create first tag" "./git_sim.sh tag -a v0.1.0 -m 'first tag'"
    run_test "tag: describe should show v0.1.0" "[[ $(./git_sim.sh describe) == 'v0.1.0' ]]"

    run_test "tag: delete a tag" "./git_sim.sh tag -d v0.1.0"
    run_test "tag: listing should show zero tags" "[[ -z \"$(./git_sim.sh tag)\" ]]"

    run_test "help: help command should run" "./git_sim.sh help | grep -q 'usage:'"

    # Test 'add .' from a subdirectory to ensure paths are correct
    run_test "add: 'add .' from subdir should correctly discover root and add all files" "(
        rm -rf .gitsim .gitignore &&
        ./git_sim.sh init &&
        touch file_root.txt &&
        mkdir -p level1/level2 &&
        touch level1/file_level1.txt &&
        touch level1/level2/file_level2.txt &&
        (cd level1/level2 && ../../git_sim.sh add .) &&
        grep -q 'file_root.txt' ./.gitsim/.data/index &&
        grep -q 'level1/file_level1.txt' ./.gitsim/.data/index &&
        grep -q 'level1/level2/file_level2.txt' ./.gitsim/.data/index
    )"

    # --- Test Summary ---
    echo ""
    echo "--- Simulator Test Suite Summary ---"
    if [[ ${#failed_tests[@]} -eq 0 ]]; then
        printf "${green}All %d simulator tests passed! \o/${x}\n" "$test_count"
    else
        printf "${red}%d out of %d simulator tests failed.${x}\n" "${#failed_tests[@]}" "$test_count"
        printf "Failed tests:\n"
        for test in "${failed_tests[@]}"; do
            printf "  - %s\n" "$test"
        done
        exit 1
    fi

    cleanup
}

main
