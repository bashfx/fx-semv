#!/usr/bin/env bash
# UAT Test Orchestrator for SEMV (BashFX style)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib/ceremony.sh"

usage() {
  cat <<EOF
SEMV UAT Test Orchestrator

Usage: tests/test.sh [list|run] [pattern]

Commands:
  list            List UAT tests in execution order
  run [pattern]   Run all UAT tests or those matching pattern

UAT layout:
  tests/uat/NN_*  Numbered feature tests (progressive)
EOF
}

action="run"
pattern=""
case "${1:-}" in
  list) action="list"; shift ;;
  run)  action="run";  shift ;;
  -h|--help) usage; exit 0 ;;
esac
pattern="${1:-}"

discover_uat() {
  if [[ -d "$SCRIPT_DIR/uat" ]]; then
    find "$SCRIPT_DIR/uat" -maxdepth 1 -type f -name "[0-9][0-9][0-9]_*.sh" -perm -u+x | sort
  fi
}

main() {
  mapfile -t files < <(discover_uat)
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No UAT tests found (tests/uat/NN_*.sh)" >&2
    exit 1
  fi
  if [[ "$action" == "list" ]]; then
    printf "%s\n" "${files[@]##*/}" | nl -w2 -s'. '
    exit 0
  fi
  local ran=0 fail=0
  for f in "${files[@]}"; do
    local bn="${f##*/}"
    if [[ -n "$pattern" ]] && [[ ! "$bn" =~ $pattern ]]; then
      continue
    fi
    test_start "$bn"
    if bash "$f"; then
      test_pass
    else
      test_fail
      fail=$((fail+1))
    fi
    test_end
    ran=$((ran+1))
  done
  echo "UAT complete. Ran: $ran, Failed: $fail"
  [[ $fail -eq 0 ]]
}

main "$@"

