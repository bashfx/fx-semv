#!/usr/bin/env bash
# Remote default HEAD robustness test (does not assume origin/main)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ceremony.sh"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/env.sh"

test_start "Remote HEAD Build Count"

# Policy: require gitsim in PATH for suite consistency (even if unused here)
if ! command -v gitsim >/dev/null 2>&1; then
  test_fail "gitsim not installed"
  test_end
  exit 1
fi

ROOT="$PROJECT_ROOT"
SEMV="$PROJECT_ROOT/semv.sh"

# Prepare a bare remote with non-main default branch "trunk"
BARE_DIR="$(fx_tmp_dir remote_bare)"
WORK_DIR="$(fx_tmp_dir remote_src)"
LOCAL_DIR="$(fx_tmp_dir remote_local)"

mkdir -p "$BARE_DIR"
git init --bare -q "$BARE_DIR/repo.git"

pushd "$WORK_DIR" >/dev/null
git init -q
git config user.name "Test User"
git config user.email "test@example.com"
echo x > f.txt
git add f.txt
git commit -qm "feat: init"
git switch -c trunk >/dev/null 2>&1 || git checkout -b trunk >/dev/null 2>&1
git remote add origin "$BARE_DIR/repo.git"
git push -u -q origin trunk
popd >/dev/null

# Set remote default HEAD to trunk
git -C "$BARE_DIR/repo.git" symbolic-ref HEAD refs/heads/trunk >/dev/null 2>&1 || true

# Clone and run rbc
pushd "$LOCAL_DIR" >/dev/null
git clone -q "$BARE_DIR/repo.git" .

if assert_exit 0 "$SEMV rbc"; then
  test_pass "rbc executes"
else
  test_fail "rbc failed"
fi

if assert_match "Build\(local:remote\) [0-9]+:[0-9]+" "$SEMV rbc"; then
  test_pass "rbc output format"
else
  test_fail "rbc output format"
fi

popd >/dev/null

fx_clean_tmp remote_bare
fx_clean_tmp remote_src
fx_clean_tmp remote_local

test_end

