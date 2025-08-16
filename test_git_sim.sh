#!/usr/bin/env bash

# test_git_sim.sh - A test runner for the git_simulator.sh script

# --- Configuration and Helpers ---

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

    # Execute the command and capture output/exit code
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

setup_sim_test() {
    echo "Setting up simulator test environment in ./${SIM_TEST_DIR}..."
    rm -rf "$SIM_TEST_DIR"
    mkdir -p "$SIM_TEST_DIR"
    cp "git_simulator.sh" "$SIM_TEST_DIR/"
    cd "$SIM_TEST_DIR" || exit 1
    chmod +x "git_simulator.sh"
}

cleanup_sim_test() {
    echo "Cleaning up simulator test environment..."
    cd ..
    rm -rf "$SIM_TEST_DIR"
}

# --- Main Test Execution ---
main() {
    setup_sim_test

    echo ""
    echo "--- Starting Git Simulator Test Suite ---"

    # Test init
    run_test "sim: init should create .gitsim directory" "./git_simulator.sh init"
    run_test "sim: .gitsim directory should exist" "[ -d .gitsim ]"

    # Test config
    run_test "sim: config set user.name" "./git_simulator.sh config user.name 'Test Sim User'"
    run_test "sim: config get user.name" "[[ \"$(./git_simulator.sh config user.name)\" == 'Test Sim User' ]]"

    # Test commit
    run_test "sim: commit should create a commit" "./git_simulator.sh commit -m 'feat: initial commit'"
    run_test "sim: commits.txt should have 1 line" "[[ $(cat .gitsim/commits.txt | wc -l) -eq 1 ]]"

    # Test tag
    run_test "sim: tag should create a tag" "./git_simulator.sh tag -a v0.1.0 -m 'first tag'"
    run_test "sim: tags.txt should contain v0.1.0" "grep -q v0.1.0 .gitsim/tags.txt"

    # Test describe
    run_test "sim: describe should return latest tag" "[[ $(./git_simulator.sh describe) == 'v0.1.0' ]]"

    # Test log
    run_test "sim: log should return commit message" "./git_simulator.sh log | grep -q 'feat: initial commit'"

    # --- New tests for staging ---

    # Create a dummy file to add
    run_test "sim: create a dummy file for staging" "echo 'hello' > dummy.txt"

    # Test add and status
    run_test "sim: add should stage the dummy file" "./git_simulator.sh add dummy.txt"
    run_test "sim: status should show the staged file" "./git_simulator.sh status --porcelain | grep -q 'A  dummy.txt'"

    # Test diff
    run_test "sim: diff --exit-code should indicate changes" "./git_simulator.sh diff --exit-code" 1

    # Test commit clearing the index
    run_test "sim: commit should succeed" "./git_simulator.sh commit -m 'feat: add dummy file'"
    run_test "sim: status should be clean after commit" "! ./git_simulator.sh status --porcelain | grep ."
    run_test "sim: diff --exit-code should be clean after commit" "./git_simulator.sh diff --exit-code" 0

    # --- New tests for .gitignore management ---
    run_test "gitignore: init should create .gitignore" "[ -f .gitignore ]"
    run_test "gitignore: .gitignore should contain .gitsim/" "grep -q '^\.gitsim/$' .gitignore"

    # Run init again to test idempotency
    run_test "gitignore: run init again" "./git_simulator.sh init"
    run_test "gitignore: .gitsim/ should only appear once" "[[ $(grep -c '^\.gitsim/$' .gitignore) -eq 1 ]]"

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

    cleanup_sim_test
}

main
