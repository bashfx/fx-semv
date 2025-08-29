#!/usr/bin/env bash
# Audit and remote comparison tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Audit and Remote Comparison"

if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"
REPO_DIR="$(fx_tmp_dir audit_remote)"

pushd "$REPO_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

printf "[package]\nname=\"ar\"\nversion=\"0.1.0\"\n" > Cargo.toml
git add Cargo.toml
git commit -qm "feat: add cargo"
git tag -a v0.1.0 -m "baseline" >/dev/null 2>&1 || true

# Audit should succeed
if assert_exit 0 "$SEMV audit"; then test_pass "audit"; else test_fail "audit"; fi

# Remote commands should not fail even if origin is absent
if assert_exit 0 "$SEMV remote"; then test_pass "remote latest"; else test_fail "remote latest"; fi
if assert_exit 0 "$SEMV upst"; then test_pass "remote compare"; else test_fail "remote compare"; fi
if assert_exit 0 "$SEMV rbc"; then test_pass "remote build compare"; else test_fail "remote build compare"; fi

popd >/dev/null
fx_clean_tmp audit_remote

test_end

