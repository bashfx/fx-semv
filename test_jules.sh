#!/usr/bin/env bash

# test.sh - A test runner for the semv script

# --- Git Simulator Hook ---
# The CWD will be inside .gitsim, so the simulator is one level up.
git() {
    ../git_sim.sh "$@"
}
export -f git

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

# --- Test Environment Setup and Teardown ---
TEST_REPO_DIR="test_repo"

setup() {
    echo "Setting up test environment in ./${TEST_REPO_DIR}..."
    rm -rf "$TEST_REPO_DIR"
    mkdir -p "$TEST_REPO_DIR"
    
    if [[ ! -f "semv_jules.sh" ]] || [[ ! -f "git_sim.sh" ]]; then
        echo "semv_jules.sh or git_sim.sh not found."
        exit 1
    fi
    cp semv_jules.sh "$TEST_REPO_DIR/semv"
    cp git_sim.sh "$TEST_REPO_DIR/"
    
    cd "$TEST_REPO_DIR" || exit 1
    chmod +x semv
    chmod +x git_sim.sh
    
    # Initialize the simulated repo, which creates .gitsim
    ./git_sim.sh init > /dev/null

    # Enter the simulated project workspace
    cd .gitsim || exit 1

    # Configure git from within the workspace
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial files inside the workspace
    echo "# Test Repo" > README.md
    cat > Cargo.toml <<EOF
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"
EOF
    cat > package.json <<EOF
{
  "name": "test-project",
  "version": "0.1.0"
}
EOF
    
    # Initial commit and tag
    git add .
    git commit -m "feat: initial project setup" > /dev/null
    git tag -a v0.1.0 -m "Initial version" > /dev/null
    
    echo "Test environment ready."
}

cleanup() {
    echo "Cleaning up test environment..."
    # We are inside .gitsim, which is inside test_repo
    cd ../..
    rm -rf "$TEST_REPO_DIR"
    echo "Cleanup complete."
}

# --- Main Test Execution ---
main() {
    setup
    
    echo ""
    echo "--- Starting SEMV Test Suite ---"
    
    # NOTE: All commands are run from inside the .gitsim workspace
    # The semv script is one level up

    run_test "info command should run successfully" "../semv info"
    run_test "validate command should pass when in sync" "../semv validate"

    echo "Introducing version drift in package.json..."
    sed -i 's/"version": "0.1.0"/"version": "0.1.1"/' package.json
    run_test "validate command should fail when drifted" "../semv validate" 1
    
    run_test "sync command should fix version drift" "../semv sync"
    run_test "validate command should pass after sync" "../semv validate"
    
    # Add a new feature commit to prepare for bump
    run_test "bump: create a new feature commit" "git commit --allow-empty -m 'feat: add another feature'"

    run_test "bump command should create new version" "../semv bump -y"
    
    run_test "git tag should be updated to v0.2.0" "git describe --tags --abbrev=0 | grep -q v0.2.0"
    run_test "Cargo.toml should be updated to 0.2.0" "grep -q 'version = \"0.2.0\"' Cargo.toml"
    run_test "package.json should be updated to 0.2.0" "grep -q '\"version\": \"0.2.0\"' package.json"

    # --- New test for dirty state handling ---
    run_test "dirty: create a new file to make the repo dirty" "echo 'dirty file' > dirty.txt"
    run_test "dirty: stage the new file" "git add dirty.txt"

    commit_count_before=$(git log | wc -l)
    run_test "dirty: bump should auto-commit dirty file" "../semv bump -y"
    commit_count_after=$(git log | wc -l)
    run_test "dirty: a new commit should have been created" "[[ $commit_count_after -gt $commit_count_before ]]"

    # --- Test Summary ---
    echo ""
    echo "--- Test Suite Summary ---"
    if [[ ${#failed_tests[@]} -eq 0 ]]; then
        printf "${green}All %d tests passed! \o/${x}\n" "$test_count"
    else
        printf "${red}%d out of %d tests failed.${x}\n" "${#failed_tests[@]}" "$test_count"
        printf "Failed tests:\n"
        for test in "${failed_tests[@]}"; do
            printf "  - %s\n" "$test"
        done
        exit 1
    fi
    
    # Run cleanup
    cleanup
}

main
