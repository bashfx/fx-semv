#!/usr/bin/env bash

# test_git_sim.sh - A test runner for the git_sim.sh script

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
    cp "git_sim.sh" "$SIM_TEST_DIR/"
    cd "$SIM_TEST_DIR" || exit 1
    chmod +x "git_sim.sh"

    # Initialize the repo. This creates the .gitsim dir.
    ./git_sim.sh init

    # All subsequent operations happen inside the simulated project folder
    cd .gitsim || exit 1
}

cleanup_sim_test() {
    echo "Cleaning up simulator test environment..."
    # We are inside .gitsim, which is inside sim_test
    current_dir=$(basename "$PWD")
    if [[ "$current_dir" == ".gitsim" ]]; then
        cd ..
    fi
    current_dir=$(basename "$PWD")
    if [[ "$current_dir" == "$SIM_TEST_DIR" ]]; then
        cd ..
    fi
    rm -rf "$SIM_TEST_DIR"
}

# --- Main Test Execution ---
main() {
    setup_sim_test

    echo ""
    echo "--- Starting Git Simulator Test Suite ---"

    # NOTE: CWD is now inside .gitsim

    # --- Test Core Functionality ---
    run_test "sim: config set user.name" "../git_sim.sh config user.name 'Test Sim User'"
    run_test "sim: config get user.name" "[[ \"$(../git_sim.sh config user.name)\" == 'Test Sim User' ]]"

    # --- Test Tagging ---
    run_test "tag: creating a tag with no commit should fail" "! ../git_sim.sh tag -a v0.0.1 -m 'fail'"

    run_test "tag: make a first commit" "../git_sim.sh commit -m 'feat: first'"
    run_test "tag: create first tag" "../git_sim.sh tag -a v0.1.0 -m 'first tag'"
    run_test "tag: describe should show v0.1.0" "[[ $(../git_sim.sh describe) == 'v0.1.0' ]]"

    run_test "tag: make a second commit" "../git_sim.sh commit -m 'feat: second'"
    run_test "tag: create second tag" "../git_sim.sh tag -a v0.2.0 -m 'second tag'"
    run_test "tag: describe should show v0.2.0" "[[ $(../git_sim.sh describe) == 'v0.2.0' ]]"

    run_test "tag: listing should show both tags" "[[ $(../git_sim.sh tag | wc -l) -eq 2 ]]"
    run_test "tag: delete a tag" "../git_sim.sh tag -d v0.1.0"
    run_test "tag: listing should show one tag" "[[ $(../git_sim.sh tag | wc -l) -eq 1 ]]"
    run_test "tag: describe should now be v0.2.0" "[[ $(../git_sim.sh describe) == 'v0.2.0' ]]"

    # --- Test Log Range ---
    run_test "log: log since v0.2.0 should be empty" "[[ -z \"$(../git_sim.sh log --pretty=format:%s v0.2.0..HEAD)\" ]]"
    run_test "log: make another commit" "../git_sim.sh commit -m 'fix: a fix'"
    run_test "log: log since v0.2.0 should now have one commit" "[[ $(../git_sim.sh log --pretty=format:%s v0.2.0..HEAD | wc -l) -eq 1 ]]"

    # --- Tests for staging ---
    run_test "staging: create a dummy file" "echo 'hello' > dummy.txt"
    run_test "staging: add should stage the dummy file" "../git_sim.sh add dummy.txt"
    run_test "staging: status should show the staged file" "../git_sim.sh status --porcelain | grep -q 'A  dummy.txt'"
    run_test "staging: diff --exit-code should indicate changes" "../git_sim.sh diff --exit-code" 1
    run_test "staging: commit should succeed" "../git_sim.sh commit -m 'feat: add dummy file'"
    run_test "staging: status should be clean after commit" "! ../git_sim.sh status --porcelain | grep ."
    run_test "staging: diff --exit-code should be clean after commit" "../git_sim.sh diff --exit-code" 0

    # --- Tests for noise and status commands ---
    run_test "noise: noise command should create 2 files" "cd .. && ./git_sim.sh noise 2 && cd .gitsim"
    run_test "noise: status should show 2 noisy files" "[[ $(../git_sim.sh status --porcelain | wc -l) -eq 2 ]]"
    run_test "noise: noisy files should not have default name" "! ../git_sim.sh status --porcelain | grep -q 'noise_file_'"
    run_test "status: status without porcelain should be human-readable" "../git_sim.sh status | grep -q 'Changes to be committed:'"
    run_test "noise: commit noisy files" "../git_sim.sh commit -m 'feat: add noisy files'"
    run_test "status: status should be clean after noisy commit" "! ../git_sim.sh status | grep 'new file:'"


    # --- Test .gitignore and help commands (from parent dir) ---
    cd .. # cd back to sim_test
    run_test "gitignore: .gitignore should exist" "[ -f .gitignore ]"
    run_test "gitignore: .gitignore should contain .gitsim/" "grep -q '^\.gitsim/$' .gitignore"
    run_test "help: help command should run successfully" "./git_sim.sh help"
    run_test "help: help output should contain 'usage:'" "./git_sim.sh help | grep -q 'usage:'"


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
