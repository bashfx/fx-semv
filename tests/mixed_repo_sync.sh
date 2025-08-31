#!/usr/bin/env bash
# Mixed repo sync test: rust/js/python alignment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Mixed Repo Sync (rust/js/python)"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
R="$(fx_tmp_dir mixed_repo)"

pushd "$R" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Seed three ecosystems at 0.1.0
printf "[package]\nname = \"mixed\"\nversion = \"0.1.0\"\n" > Cargo.toml
printf "{\n  \"name\": \"mixed\",\n  \"version\": \"0.1.0\"\n}\n" > package.json
printf "[project]\nname = \"mixed\"\nversion = \"0.1.0\"\n" > pyproject.toml

git add .
git commit -qm "feat: init mixed repo"
git tag -a v0.1.0 -m baseline >/dev/null 2>&1 || true

# Validate should pass
if assert_exit 0 "$SEMV validate"; then test_pass "validate (aligned)"; else test_fail "validate (aligned)"; fi

# Introduce drift in one package (js)
sed -i 's/"version": "0.1.0"/"version": "0.1.1"/' package.json

# Drift should be detected
if assert_exit 0 "$SEMV drift"; then test_pass "drift detected"; else test_fail "drift not detected"; fi

# Sync to resolve
if assert_exit 0 "$SEMV sync"; then test_pass "sync"; else test_fail "sync"; fi
if assert_exit 0 "$SEMV validate"; then test_pass "validate (post-sync)"; else test_fail "validate (post-sync)"; fi

popd >/dev/null
fx_clean_tmp mixed_repo

test_end

