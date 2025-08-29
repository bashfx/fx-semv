## Project Context

SEMV is a BashFX v3-compliant semantic version manager. It assembles from `parts/` via `build.sh` into `semv.sh`. The project now follows XDG+ canonical paths with `*_HOME` variables (e.g., `SEMV_ETC_HOME`) and uses a modular command surface with `do_*` high‑order functions.

Key architectural points:
- Streams: messages on stderr, values on stdout.
- Flags: 0=true semantics (BashFX pattern), `DEBUG_MODE/TRACE_MODE/QUIET_MODE` supported.
- XDG+: canonical `SEMV_ETC_HOME`, `SEMV_DATA_HOME`, `SEMV_LIB_HOME`; RC at `${SEMV_ETC_HOME}/.semv.rc` with migration.
- Tagging: all retag operations explicitly tag the resolved commit, never implicit HEAD.
- Baseline: repos must be “semv-initialized” (have a semver tag); guidance via `semv mark1`/`semv new`.

## What’s Done (Highlights)
- Build: `build.sh` fixed help text; parts assembled cleanly.
- Tagging: retag helper abstraction; resolved-commit tagging; stable/beta flows.
- Config: `*_HOME` canonical vars; RC migration; lifecycle/status surfaces updated.
- Commands implemented: `bc`, `mark1`, `pre-commit`, `audit`, `remote`, `upst`, `rbc`.
- Validate/Drift: compares current sources (package vs tag); “next” is informational only; warns (doesn’t fail) on dirty state.
- Guards: `require_semv_baseline()` applied to bump/promote.
- Tests: comprehensive harness (`tests/test.sh`) + lib helpers, integration and unit tests; `ci-test.sh` optional runner.
- Docs: README/semv_commands_reference aligned; README_TEST.md added.

## How To Run
- Build: `./build.sh -c && ./build.sh`
- Syntax: `bash -n semv.sh`
- Tests:
  - `./tests/test.sh health`
  - `./tests/test.sh run` (requires `gitsim` in PATH for some tests)
  - Optional CI helper: `./ci-test.sh`

## Environment
- Color output assumed; assertions strip ANSI when matching.
- Use XDG cache for temp dirs with fallback to `./tmp/tests`.
- `gitsim` is expected to be available for full test coverage; harness skips only in CI helper when absent.

## Current Test Suite (Key Files)
- `tests/test_simple.sh`: basic CLI smoke.
- `tests/test_semv.sh`: quick checks with timeouts.
- `tests/comprehensive_test.sh`: surface coverage, skips unimplemented.
- `tests/integration_repo_sync.sh`: repo init → validate/drift/sync → bump.
- `tests/mark1_baseline.sh`: mark1 from package/default.
- `tests/pre_commit.sh`: aligned passes; drift blocks.
- `tests/promote_stable.sh`: stable retag + snapshot.
- `tests/audit_remote.sh`: audit + remote ops (no origin required).
- `tests/validate_drift_edges.sh`: validate/drift edge cases.
- `tests/baseline_guard.sh`: bump/promote guard prior to baseline.

## Roadmap & Tasks (Status)

Milestone 7 — Command Surface Completion (done)
- Implemented: `bc`, `mark1`, `pre-commit`, `audit`, `remote`, `upst`, `rbc` with tests.

Milestone 8 — Baseline + Validate/Drift Hardening (in progress)
- Guard remaining semv‑aware flows (baseline guidance) — add where needed.
- Add edge tests (done for two core cases).

Milestone 9 — Promotion Coverage (pending)
- Add tests for `promote beta` and `promote release` retag/snapshot behavior.

Milestone 10 — Remote Robustness (pending)
- Use `which_main`/remote HEAD for remote build count; add test that doesn’t assume `origin/main`.

Milestone 11 — Multi‑Language Sync Tests (pending)
- Create rust/js/python mixed repo test asserting sync + validate.

Milestone 12 — Dispatcher Hybrid Mapping (flagged) (pending)
- Implement behind feature flag; default to explicit mapping.

Milestone 13 — Pre‑commit Auto Staging (optional) (pending)
- Offer staging for version files on drift resolution; add flag and tests.

## Quick Start For Next Agent
1) Build and run tests: see “How To Run”. Ensure `gitsim` is available.
2) Pick up M9 (promotion tests) and M10 (remote robustness) — both are high‑signal and low risk.
3) Keep logs in `SESSION.md`; update `TASKS.md` as you complete items.
4) Maintain BashFX patterns (stderr/stdout; 0=true flags; function ordinality).

## Notes
- Integration tests assume no network/push; push steps are guarded/optional.
- Validate semantics: treat “next” as informational; only fail on actual drift/structure errors.
- Baseline guard ensures users run `semv mark1`/`semv new` when needed.

