#!/usr/bin/env bash
# BashFX test ceremony helpers
set -euo pipefail

test_start() {
  local name="$1"
  echo "🧪 TEST: $name"
  echo "────────────────────────────────────────"
}

test_pass() {
  local msg="${1:-PASS}"
  echo "  ✓ $msg"
}

test_fail() {
  local msg="${1:-FAIL}"
  echo "  ✗ $msg"
}

test_end() {
  echo "────────────────────────────────────────"
  echo
}

