#!/usr/bin/env bash
#
# test_stakeholder_fixes.sh - Validate all STAKE-XX fixes
# Tests for STAKE-01 through STAKE-05 stakeholder requirements
#

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SEMV_CMD="$PROJECT_ROOT/semv.sh"
TEST_TMP="/tmp/semv-test-$$"
VIRTUAL_HOME="$TEST_TMP/virtual-home"
ORIGINAL_XDG_HOME="${XDG_HOME:-}"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test utilities
log_test() {
    echo -e "${BLUE}🧪 TEST: $1${NC}"
    ((TOTAL_TESTS++))
}

log_pass() {
    echo -e "  ${GREEN}✓ PASS${NC}: $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "  ${RED}✗ FAIL${NC}: $1"
    ((FAILED_TESTS++))
}

log_info() {
    echo -e "  ${YELLOW}ℹ${NC} $1"
}

# Run a test function with isolated environment
run_isolated_test() {
    local test_func="$1"
    local test_tmp_dir="$TEST_TMP/${test_func}_$$"
    
    # Create isolated test directory
    mkdir -p "$test_tmp_dir"
    
    # Run test function directly (not in subshell to preserve counters)
    export TEST_WORK_DIR="$test_tmp_dir"
    cd "$PROJECT_ROOT"
    "$test_func"
    local result=$?
    
    # Clean up test-specific artifacts
    rm -rf "$test_tmp_dir" 2>/dev/null || true
    
    return $result
}

cleanup() {
    # Restore original XDG_HOME
    if [[ -n "$ORIGINAL_XDG_HOME" ]]; then
        export XDG_HOME="$ORIGINAL_XDG_HOME"
    else
        unset XDG_HOME
    fi
    
    # Clean up all test artifacts
    rm -rf "$TEST_TMP" 2>/dev/null || true
    
    # Clean up any files that might have been created in the project
    rm -f "$PROJECT_ROOT/semv.build" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/build.inf" 2>/dev/null || true
}

setup() {
    # Create virtual environment
    mkdir -p "$VIRTUAL_HOME"
    mkdir -p "$TEST_TMP"
    
    # Set up virtual XDG_HOME to isolate all data/config/cache operations
    export XDG_HOME="$VIRTUAL_HOME"
    
    # Create standard XDG directories in virtual home
    mkdir -p "$VIRTUAL_HOME/.local/"{bin,lib,etc,data}
    mkdir -p "$VIRTUAL_HOME/.cache/tmp"
    
    cd "$PROJECT_ROOT"
    
    log_info "Using virtual home: $VIRTUAL_HOME"
    log_info "XDG_HOME set to: $XDG_HOME"
}

# STAKE-01: Options flags documented in help
test_stake_01_help_flags() {
    log_test "STAKE-01: Options flags documented in help"
    
    local help_output
    help_output=$("$SEMV_CMD" --help 2>&1)
    
    if echo "$help_output" | grep -q -- "--build-dir"; then
        log_pass "build-dir flag documented in help"
    else
        log_fail "build-dir flag missing from help"
        return 1
    fi
    
    if echo "$help_output" | grep -q -- "--no-cursor"; then
        log_pass "no-cursor flag documented in help"
    else
        log_fail "no-cursor flag missing from help"
        return 1
    fi
    
    if echo "$help_output" | grep -q "FLAGS:"; then
        log_pass "FLAGS section exists in help"
    else
        log_fail "FLAGS section missing from help"
        return 1
    fi
}

# STAKE-02: Build directory functionality
test_stake_02_build_dir() {
    log_test "STAKE-02: Build directory argument parsing"
    
    local test_dir="${TEST_WORK_DIR:-$TEST_TMP}/build-test"
    mkdir -p "$test_dir"
    
    # Test default behavior (no build-dir flag)
    cd "$test_dir"
    if "$SEMV_CMD" build >/dev/null 2>&1; then
        if [[ -f "./semv.build" ]]; then
            log_pass "default behavior creates file in current directory"
        else
            log_fail "default behavior didn't create file in current directory"
            return 1
        fi
    else
        log_fail "default build command failed"
        return 1
    fi
    rm -f "./semv.build"
    cd "$PROJECT_ROOT"
    
    # Test --build-dir=path syntax
    if "$SEMV_CMD" build --build-dir="$test_dir" >/dev/null 2>&1; then
        if [[ -f "$test_dir/semv.build" ]]; then
            log_pass "build-dir with = syntax works"
        else
            log_fail "build-dir with = syntax didn't create file"
            return 1
        fi
    else
        log_fail "build-dir with = syntax failed"
        return 1
    fi
    
    # Test --build-dir path syntax
    rm -f "$test_dir/semv.build"
    if "$SEMV_CMD" build --build-dir "$test_dir" >/dev/null 2>&1; then
        if [[ -f "$test_dir/semv.build" ]]; then
            log_pass "build-dir with space syntax works"
        else
            log_fail "build-dir with space syntax didn't create file"
            return 1
        fi
    else
        log_fail "build-dir with space syntax failed"
        return 1
    fi
}

# STAKE-02a: Build command rename
test_stake_02a_build_command() {
    log_test "STAKE-02a: Build command renamed from 'file' to 'build'"
    
    # Test that 'build' command exists
    if "$SEMV_CMD" build --help >/dev/null 2>&1; then
        log_pass "'build' command exists"
    else
        log_fail "'build' command doesn't exist"
        return 1
    fi
    
    # Test that 'file' command no longer exists (should return error)
    local file_output
    if file_output=$("$SEMV_CMD" file 2>&1) && echo "$file_output" | grep -q "Invalid command"; then
        log_pass "'file' command properly removed"
    elif echo "$file_output" | grep -q "Invalid command"; then
        log_pass "'file' command properly removed"
    else
        log_fail "'file' command still exists"
        return 1
    fi
    
    # Test help shows 'build' command
    local help_output
    help_output=$("$SEMV_CMD" --help 2>&1)
    if echo "$help_output" | grep -q "build.*Generate build info"; then
        log_pass "'build' command documented in help"
    else
        log_fail "'build' command not properly documented"
        return 1
    fi
}

# STAKE-02c: Build file content validation
test_stake_02c_build_content() {
    log_test "STAKE-02c: Build file key=value content generation"
    
    local test_dir="${TEST_WORK_DIR:-$TEST_TMP}/content-test"
    mkdir -p "$test_dir"
    
    if "$SEMV_CMD" build --build-dir="$test_dir" >/dev/null 2>&1; then
        local build_file="$test_dir/semv.build"
        if [[ -f "$build_file" ]]; then
            # Check for required key=value pairs
            local required_keys=("user=" "project=" "branch=" "main_branch=" "changes=" "build_local=" "current_version=" "timestamp=")
            local missing_keys=()
            
            for key in "${required_keys[@]}"; do
                if ! grep -q "^$key" "$build_file"; then
                    missing_keys+=("$key")
                fi
            done
            
            if [[ ${#missing_keys[@]} -eq 0 ]]; then
                log_pass "All required key=value pairs present"
            else
                log_fail "Missing keys: ${missing_keys[*]}"
                return 1
            fi
            
            # Check for comment header
            if grep -q "^# Build Information Generated by SEMV" "$build_file"; then
                log_pass "Proper header comment present"
            else
                log_fail "Missing header comment"
                return 1
            fi
            
        else
            log_fail "Build file not created"
            return 1
        fi
    else
        log_fail "Build command failed"
        return 1
    fi
}

# STAKE-04: Branch protection
test_stake_04_branch_protection() {
    log_test "STAKE-04: Branch protection for version bumps"
    
    # Save current branch
    local original_branch
    original_branch=$(git branch --show-current)
    
    # Create and switch to test branch
    git checkout -b "test-branch-$$" >/dev/null 2>&1 || true
    
    # Test that bump fails on non-main branch
    local output
    if output=$("$SEMV_CMD" bump 2>&1); then
        log_fail "Bump succeeded on non-main branch (should fail)"
        git checkout "$original_branch" >/dev/null 2>&1
        git branch -D "test-branch-$$" >/dev/null 2>&1 || true
        return 1
    else
        if echo "$output" | grep -q "only allowed on main"; then
            log_pass "Bump correctly blocked on non-main branch"
        else
            log_fail "Bump failed but with wrong error message"
            git checkout "$original_branch" >/dev/null 2>&1
            git branch -D "test-branch-$$" >/dev/null 2>&1 || true
            return 1
        fi
    fi
    
    # Cleanup: switch back and delete test branch
    git checkout "$original_branch" >/dev/null 2>&1
    git branch -D "test-branch-$$" >/dev/null 2>&1 || true
    
    log_pass "Branch protection working correctly"
}

# STAKE-05: Enhanced bash sync
test_stake_05_bash_sync() {
    log_test "STAKE-05: Enhanced bash sync with parts/ detection"
    
    # Since we're in a project with parts/, test auto-detection
    local output
    if output=$("$SEMV_CMD" -t sync 2>&1); then
        if echo "$output" | grep -q "Auto-detected bash target file: parts/"; then
            log_pass "Auto-detected parts/ structure"
        else
            log_fail "Failed to auto-detect parts/ structure"
            return 1
        fi
        
        if echo "$output" | grep -q "Found first part from build.map"; then
            log_pass "Successfully used build.map for detection"
        else
            log_fail "Failed to use build.map for detection"
            return 1
        fi
        
        if echo "$output" | grep -q "Version synchronization completed"; then
            log_pass "Sync completed successfully"
        else
            log_fail "Sync did not complete successfully"
            return 1
        fi
    else
        log_fail "Sync command failed"
        return 1
    fi
}

# Run all tests
main() {
    echo -e "${BLUE}🚀 SEMV Stakeholder Fixes Test Suite${NC}"
    echo "Testing fixes for STAKE-01 through STAKE-05"
    echo

    setup
    trap cleanup EXIT

    # Run tests (continue on failure to get full report)
    run_isolated_test test_stake_01_help_flags || true
    run_isolated_test test_stake_02_build_dir || true  
    run_isolated_test test_stake_02a_build_command || true
    run_isolated_test test_stake_02c_build_content || true
    run_isolated_test test_stake_04_branch_protection || true
    run_isolated_test test_stake_05_bash_sync || true

    echo
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "Total tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}✅ All stakeholder fixes validated successfully!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed. Please check the output above.${NC}"
        exit 1
    fi
}

main "$@"