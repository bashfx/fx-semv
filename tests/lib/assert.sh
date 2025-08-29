#!/usr/bin/env bash
# BashFX test assert helpers
set -euo pipefail

assert_exit() {
  local code="$1"; shift
  local cmd="$*"
  set +e
  eval "$cmd" >/dev/null 2>&1
  local rc=$?
  set -e
  if [[ "$rc" -eq "$code" ]]; then
    return 0
  else
    echo "Expected exit $code, got $rc for: $cmd"
    return 1
  fi
}

assert_match() {
  local pattern="$1"; shift
  local cmd="$*"
  local out
  set +e
  out=$(eval "$cmd" 2>&1)
  local rc=$?
  set -e
  # Strip ANSI color/escape codes for matching robustness
  out=$(printf "%s" "$out" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g')
  if [[ $rc -eq 0 && "$out" =~ $pattern ]]; then
    return 0
  else
    echo "Output did not match /$pattern/: $out"
    return 1
  fi
}
