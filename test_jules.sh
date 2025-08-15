#!/usr/bin/env bash

# test.sh - A test runner for the semv script
# This script creates a temporary git repository to test semv's functionality.

# --- Git Simulator Hook ---
# Override the 'git' command to use our simulator.
# This ensures all git operations are sandboxed and don't affect the real environment.
git() {
    # The simulator script is copied into the test directory,
    # so we can call it directly.
    ./git_simulator.sh "$@"
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

# Function to set up the test repository
setup() {
    echo "Setting up test environment in ./${TEST_REPO_DIR}..."
    rm -rf "$TEST_REPO_DIR"
    mkdir -p "$TEST_REPO_DIR"
    
    # Copy semv and simulator scripts
    if [[ ! -f "semv_jules.sh" ]] || [[ ! -f "git_simulator.sh" ]]; then
        echo "${fail_glyph} 'semv_jules.sh' or 'git_simulator.sh' script not found. Cannot run tests."
        exit 1
    fi
    cp semv_jules.sh "$TEST_REPO_DIR/semv"
    cp git_simulator.sh "$TEST_REPO_DIR/"
    
    cd "$TEST_REPO_DIR" || exit 1
    chmod +x semv
    chmod +x git_simulator.sh
    
    # Configure git
    git init > /dev/null
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial files
    echo "# Test Repo" > README.md
    
    # Rust project
    cat > Cargo.toml <<EOF
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"
EOF

    # JS project
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

# Function to clean up the test repository
cleanup() {
    echo "Cleaning up test environment..."
    cd ..
    rm -rf "$TEST_REPO_DIR"
    echo "Cleanup complete."
}

# --- Main Test Execution ---

main() {
    # Run setup
    setup
    
    echo ""
    echo "--- Starting SEMV Test Suite ---"
    
    # Test Suite
    run_test "info command should run successfully" "./semv info"
    run_test "validate command should pass when in sync" "./semv validate"

    # Test drift detection
    echo "Introducing version drift in package.json..."
    sed -i 's/"version": "0.1.0"/"version": "0.1.1"/' package.json
    run_test "validate command should fail when drifted" "./semv validate" 1
    
    # Test sync functionality
    run_test "sync command should fix version drift" "./semv sync"
    run_test "validate command should pass after sync" "./semv validate"
    
    # Test bump functionality
    run_test "bump command should create new version" "./semv bump -y"
    
    # Verification after bump
    run_test "git tag should be updated to v0.2.0" "git describe --tags --abbrev=0 | grep -q v0.2.0"
    run_test "Cargo.toml should be updated to 0.2.0" "grep -q 'version = \"0.2.0\"' Cargo.toml"
    run_test "package.json should be updated to 0.2.0" "grep -q '\"version\": \"0.2.0\"' package.json"

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

# Run the main function
main
