#!/usr/bin/env bash
# BashFX test env helpers
set -euo pipefail

# Resolve project root (tests/ is expected under project root)
_env_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Climb up to find project root (presence of build.sh or parts/)
_d="$_env_dir"
for _i in 1 2 3 4; do
  if [[ -f "$_d/../build.sh" || -d "$_d/../parts" ]]; then
    PROJECT_ROOT="$(cd "$_d/.." && pwd)"
    break
  fi
  _d="$_d/.."
done
: "${PROJECT_ROOT:=$(cd "$_env_dir/../.." && pwd)}"

# XDG cache base
FX_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

fx_tmp_dir() {
  # Use project-local tmp dir for stability in sandboxed environments
  local name="$1"
  local p="$PROJECT_ROOT/tmp/tests/$name"
  mkdir -p "$p"
  printf "%s\n" "$p"
}

fx_clean_tmp() {
  local name="$1"
  rm -rf "$FX_CACHE_HOME/tmp/$(basename "$PROJECT_ROOT")/tests/$name" 2>/dev/null || true
  rm -rf "$PROJECT_ROOT/tmp/tests/$name" 2>/dev/null || true
}
