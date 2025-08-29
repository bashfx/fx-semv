#!/usr/bin/env bash
# Integration: repository sync/validate/bump using real git (KB test paradigm)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "SEM V Integration: repo sync/validate/bump"

# Require gitsim availability (environment standard), though this test uses real git
if ! command -v gitsim >/dev/null 2>&1; then
  echo "gitsim is required for suite; not found in PATH" >&2
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir repo_integration)"

pushd "$REPO_DIR" >/dev/null

# Initialize git repo
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Seed project files
printf "[package]\nname = \"test-project\"\nversion = \"0.1.0\"\n" > Cargo.toml
printf "{\n  \"name\": \"test-project\",\n  \"version\": \"0.1.0\"\n}\n" > package.json
git add .
git commit -qm "feat: initial project setup"
git tag -a v0.1.0 -m "Initial version" >/dev/null 2>&1 || true

# Validate should pass
if assert_exit 0 "$SEMV validate"; then test_pass "validate (in sync)"; else test_fail "validate (in sync)"; fi

# Introduce drift in package.json
sed -i 's/"version": "0.1.0"/"version": "0.1.1"/' package.json
# Drift should be detected; drift returns 0 on drift
if assert_exit 0 "$SEMV drift"; then test_pass "drift detected"; else test_fail "drift not detected"; fi

# Sync should resolve
if assert_exit 0 "$SEMV sync"; then test_pass "sync"; else test_fail "sync"; fi
if assert_exit 0 "$SEMV validate"; then test_pass "validate (post-sync)"; else test_fail "validate post-sync"; fi

# Add a feature commit and bump
git commit --allow-empty -qm 'feat: another feature'
if assert_exit 0 "$SEMV bump -y"; then test_pass "bump"; else test_fail "bump"; fi

# Latest tag should be v0.2.0 (minor bump from 0.1.x)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [[ "$LATEST_TAG" =~ ^v0\.2\.0$ ]]; then test_pass "tag v0.2.0"; else test_fail "tag not v0.2.0 ($LATEST_TAG)"; fi

popd >/dev/null
fx_clean_tmp repo_integration

test_end
