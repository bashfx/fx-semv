#!/usr/bin/env bash
# BashFX Test Suite Dispatcher (lightweight)

set -euo pipefail

# Flags
opt_yes=1   # 0=true, 1=false
opt_quiet=1 # 0=true, 1=false
category="all"
action="run"

usage() {
  cat <<EOF
BashFX Test Dispatcher

Usage: tests/test.sh [list|run|health] [pattern] [flags]

Commands:
  list                 List discovered test files
  run [pattern]        Run all tests or those matching pattern
  health               Validate test syntax (bash -n)

Flags:
  -y                   Auto-yes (no prompts)
  -q                   Quiet mode (less ceremony)

Discovery:
  • Looks in ./tests and ./test for executable *.sh files
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    list) action="list"; shift ;;
    run)  action="run";  shift ;;
    health) action="health"; shift ;;
    -y)   opt_yes=0; shift ;;
    -q)   opt_quiet=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) pattern="${1}"; shift ;;
  esac
done

discover_tests() {
  # Prefer ./tests then ./test; include both if present
  local files=()
  if [[ -d tests ]]; then
    while IFS= read -r -d '' f; do files+=("$f"); done < <(find tests -maxdepth 1 -type f -name "*.sh" -perm -u+x -print0)
  fi
  if [[ -d test ]]; then
    while IFS= read -r -d '' f; do files+=("$f"); done < <(find test -maxdepth 1 -type f -name "*.sh" -perm -u+x -print0)
  fi
  # Filter out the dispatcher itself to avoid recursion
  printf '%s\n' "${files[@]}" | rg -v '^tests/test\.sh$' | sort
}

run_test_file() {
  local file="$1"
  local name
  name="$(basename "$file")"
  if [[ $opt_quiet -ne 0 ]]; then
    echo "🧪 TEST: $name"
  fi
  bash "$file"
  local rc=$?
  if [[ $opt_quiet -ne 0 ]]; then
    if [[ $rc -eq 0 ]]; then echo "  ✓ PASS"; else echo "  ✗ FAIL ($rc)"; fi
    echo "────────────────────────────────────────────────"
  fi
  return $rc
}

main() {
  local all tests rc=0
  mapfile -t all < <(discover_tests)

  if [[ "$action" == "list" ]]; then
    if [[ ${#all[@]} -eq 0 ]]; then echo "No tests found"; exit 1; fi
    printf "• %s\n" "${all[@]}"
    exit 0
  fi

  if [[ "$action" == "health" ]]; then
    if [[ ${#all[@]} -eq 0 ]]; then echo "No tests found"; exit 1; fi
    local bad=0
    for f in "${all[@]}"; do
      if ! bash -n "$f" 2>/dev/null; then echo "Syntax error: $f"; bad=1; fi
    done
    [[ $bad -eq 0 ]] && echo "✅ All tests pass syntax check" || echo "❌ Syntax issues found"
    exit $bad
  fi

  if [[ -n "${pattern:-}" ]]; then
    mapfile -t tests < <(printf '%s\n' "${all[@]}" | grep -E "$pattern" || true)
  else
    tests=("${all[@]}")
  fi

  if [[ ${#tests[@]} -eq 0 ]]; then echo "No matching tests"; exit 1; fi

  if [[ $opt_quiet -ne 0 ]]; then
    echo "🚀 BashFX Test Suite"
    echo "Found ${#tests[@]} test(s)"
    echo
  fi

  local pass=0 fail=0
  for t in "${tests[@]}"; do
    if run_test_file "$t"; then ((pass++)); else ((fail++)); rc=1; fi
  done

  if [[ $opt_quiet -ne 0 ]]; then
    echo "📊 Summary: ${pass} pass, ${fail} fail"
  fi
  return $rc
}

main "$@"; exit $?
