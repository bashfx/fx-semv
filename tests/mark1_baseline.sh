#!/usr/bin/env bash
# Mark1 baseline tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Mark1 Baseline Initialization"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir mark1_repo)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Case A: With package versions
printf "[package]\nname=\"m1\"\nversion=\"0.3.0\"\n" > Cargo.toml
git add Cargo.toml
git commit -qm "feat: add cargo"

if assert_exit 0 "$SEMV new"; then test_pass "mark1 from package"; else test_fail "mark1 from package"; fi
TAG_A=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [[ "$TAG_A" == "v0.3.0" ]]; then test_pass "baseline tag v0.3.0"; else test_fail "baseline tag not v0.3.0 ($TAG_A)"; fi

# Case B: No package versions (new repo)
popd >/dev/null
fx_clean_tmp mark1_repo
REPO_DIR="$(fx_tmp_dir mark1_repo2)"
pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo "readme" > README.md
git add README.md
git commit -qm "feat: init"
if assert_exit 0 "$SEMV new"; then test_pass "mark1 default"; else test_fail "mark1 default"; fi
TAG_B=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [[ "$TAG_B" == "v0.0.1" ]]; then test_pass "baseline tag v0.0.1"; else test_fail "baseline tag not v0.0.1 ($TAG_B)"; fi

popd >/dev/null
fx_clean_tmp mark1_repo2

test_end

