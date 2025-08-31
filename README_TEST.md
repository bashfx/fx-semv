## SEMV Test Suite — Usage & Coverage

This document explains how to run the test suite, what each test covers, and how to add new tests following the BashFX v3 testing pattern.

## Overview

- Tests live in `tests/` and use a lightweight harness with three helpers:
  - `tests/lib/ceremony.sh`: Standardized start/pass/fail/end output.
  - `tests/lib/assert.sh`: Assertions (`assert_exit`, `assert_match`) with ANSI‑stripping for stable matching.
  - `tests/lib/env.sh`: Project root detection, XDG cache paths, and safe tmp directory fallback.
- Dispatcher: `test.sh`
  - `list` — list test files
  - `health` — syntax check for all tests (`bash -n`)
  - `run [pattern]` — run all or matching tests

## Running Tests

- List tests:
  - `./test.sh list`
- Syntax health:
  - `./test.sh health`
- Run all tests:
  - `./test.sh run`
- Run a specific test by filename pattern:
  - `./test.sh run test_simple.sh`
- Minimal CI helper (optional):
  - `./tests/ci-test.sh` (runs `health` + executes tests; skips gitsim tests if `gitsim` is missing)

## Environment

- Color output is expected; tests normalize ANSI codes for matching.
- Temporary directories use XDG cache (`$XDG_CACHE_HOME`) with a safe fallback to `./tmp/tests/<name>` if cache is not writable.
- Gitsim policy: `gitsim` is considered available in the environment. Some tests require it and will fail if missing.

## Test Coverage

- `tests/test_simple.sh`
  - Purpose: Smoke test for basic CLI commands.
  - Coverage: `help`, `next`, `get bash`, `get all`.
  - Pattern: Harnessed ceremony + asserts; robust to colored output.

- `tests/test_semv.sh`
  - Purpose: Quick functionality check with timeouts for long operations.
  - Coverage: `help`, `next`, `get all`, `info` (with timeouts to constrain runtime).
  - Notes: Good for quick manual sanity in dynamic environments.

- `tests/comprehensive_test.sh`
  - Purpose: A broader surface pass of key commands.
  - Coverage: `help`, `next`, `info`, `status`, `get bash`, `get all`, and `bc` (build count).
  - Notes: `bc` is implemented via `do_build_count`.

- `tests/test_git_sim.sh`
  - Purpose: Verify `gitsim` availability and minimal operations.
  - Coverage: `gitsim home-init`, `gitsim home-path`.
  - Policy: Fails if `gitsim` is not installed/available in PATH.

- `tests/integration_repo_sync.sh`
  - Purpose: End‑to‑end repo workflow in an isolated temp directory using real `git`.
  - Coverage:
    - Initialize repo, set user config.
    - Seed `Cargo.toml`/`package.json` with version `0.1.0` and tag `v0.1.0`.
    - `validate` in‑sync, then introduce drift and assert `validate` fails.
    - `sync` resolves drift; `validate` passes.
    - Add a feature commit and `bump` → assert latest tag is `v0.2.0`.
  - Notes: Requires `gitsim` in the environment (for overall suite policy) though it uses real `git` for repo actions; uses XDG tmp fallback for FS safety.

## Adding New Tests

- Create a new file in `tests/` and source the harness libs:
  - `source "$SCRIPT_DIR/lib/ceremony.sh"`
  - `source "$SCRIPT_DIR/lib/assert.sh"`
  - `source "$SCRIPT_DIR/lib/env.sh"`
- Use ceremony wrappers:
  - `test_start "Descriptive Name"`
  - `test_pass "step label"` / `test_fail "step label"`
  - `test_end`
- Prefer assertions:
  - `assert_exit <code> "<command>..."`
  - `assert_match "<regex>" "<command>..."`
- Keep tests self‑contained and side‑effect free outside their temp dirs (use `fx_tmp_dir <name>` and `fx_clean_tmp <name>` as needed).
- Follow BashFX v3 ceremony for clarity and consistent UX.

## Notes & Conventions

- Streams: Tests may read stderr/ANSI output; assertions normalize ANSI codes to reduce fragility.
- Timeouts: Use `timeout <seconds> <command>` where long‑running operations are possible.
- Skips vs failures: For critical dependencies (e.g., `gitsim`), fail when absent; for optional features, prefer graceful skips with an explanatory message.

## Practical Examples

- Run a single test:
  - `./test.sh run test_simple.sh`
- Run only tests matching a pattern:
  - `./test.sh run integration`
- CI helper locally:
  - `./tests/ci-test.sh`

This harness balances visual ceremony for manual runs with pragmatic assertions for automation. Extend coverage by following the pattern above; prefer small, focused tests and use the integration test for end‑to‑end flows.
