#!/usr/bin/env bash
# Pre-commit validation tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Pre-commit Validation"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir precommit_repo)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Seed project with aligned state
printf "[package]\nname=\"pc\"\nversion=\"0.1.0\"\n" > Cargo.toml
git add Cargo.toml
git commit -qm "feat: add cargo"
git tag -a v0.1.0 -m "baseline" >/dev/null 2>&1 || true

if assert_exit 0 "$SEMV pre-commit"; then test_pass "pre-commit aligned"; else test_fail "pre-commit aligned"; fi

# Introduce drift
sed -i 's/0.1.0/0.1.1/' Cargo.toml
if assert_exit 1 "$SEMV pre-commit"; then test_pass "pre-commit drift blocks"; else test_fail "pre-commit drift blocks"; fi

popd >/dev/null
fx_clean_tmp precommit_repo

test_end

