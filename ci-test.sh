#!/usr/bin/env bash
# Minimal CI test runner for SEMV
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ -x ./build.sh ]]; then
  ./build.sh -c >/dev/null
  ./build.sh >/dev/null
fi

echo "[ci] syntax health"
./tests/test.sh health

echo "[ci] discovering tests"
mapfile -t TESTS < <(./tests/test.sh list | sed 's/^• \s*//')

have_gitsim=0
if command -v gitsim >/dev/null 2>&1; then
  have_gitsim=1
fi

fail=0
run_one() {
  local path="$1"
  local base rc
  base="$(basename "$path")"
  echo "[ci] running: $base"
  set +e
  ./tests/test.sh run "$base"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "[ci] fail: $base (rc=$rc)" >&2
    fail=1
  fi
}

if [[ $have_gitsim -eq 1 ]]; then
  for t in "${TESTS[@]}"; do run_one "$t"; done
else
  echo "[ci] gitsim missing; running non-gitsim tests only" >&2
  for t in "${TESTS[@]}"; do
    case "$t" in
      (*test_git_sim.sh|*integration_repo_sync.sh) ;; # skip
      (*) run_one "$t" ;;
    esac
  done
fi

if [[ $fail -ne 0 ]]; then
  echo "[ci] FAIL: one or more tests failed" >&2
  exit 1
else
  echo "[ci] PASS"
  exit 0
fi
