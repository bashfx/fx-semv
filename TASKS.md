# SEMV Tasks (Point-Based)

Point scale: 1 (tiny), 2 (small), 3 (medium), 5 (large). Focus on low‑risk, high‑value first.

## M1 — Docs + Safe Fixes
- [x] Fix `build.sh` help default text to `semv.sh` (1)
- [x] Retagging: tag at resolved commit for `latest-dev`, `latest`, and stable snapshot (3)
- [x] Add alias `SEMV_ETC` (no behavior change) and document usage (2)
- [x] Start SESSION.md entries for this effort (1)

## M2 — Config Path Consolidation
- [x] Define `SEMV_ETC` as primary; keep `SEMV_CONFIG` as alias (2)
- [x] RC location: write/read from `${SEMV_ETC}/.semv.rc`, with migration if old file exists (3)
- [x] Update status/install/uninstall surfaces to display `SEMV_ETC` (2)
- [x] Remove `SEMV_HOME` creation; compute legacy RC path inline for migration only (2)

## M3 — Test Alignment (KB Pattern)
- [x] Create `tests/test.sh` dispatcher with ceremony and filters (3)
- [x] Move `test/` → `tests/` and adjust paths (2)
- [x] Port existing tests to standardized pattern and XDG cache usage (5)
- [x] Port `tests/test_simple.sh` using ceremony + asserts (1)
 - [x] Port `tests/comprehensive_test.sh` to harnessed asserts (2)
- [x] Add common `tests/lib` helpers for env/ceremony/asserts (2)
- [x] Add syntax/discovery health checks (1)
- [x] Remove legacy `tests/test_jules.sh`; reimplement critical coverage as `tests/integration_repo_sync.sh` (3)

## M4 — Redundancy Reduction
- [x] Add `__tag_delete`, `__tag_to`, `__retag_to` helpers (2)
- [x] Replace ad‑hoc tag operations with helpers in promote flows (3)
- [x] Identify and centralize repeated printer + guard patterns (3)

## M5 — Documentation Sync
- [x] README: set BashFX v3 and fix links to docs (2)
- [x] Semv docs: verify promote/sync text matches code behavior (2)

## M6 — Deferred Paradigm Review
- [x] Survey all `do_*` signatures and arg usage (3)
- [x] RFC: dispatcher lazy‑vars refactor plan (3)

## M7 — Command Surface Completion
// Consolidated from dispatcher review and prior work
- [x] Implement `do_build_count` via `__git_build_count` (1)
- [x] Implement `do_mark_1` (init repo; create v0.0.1 if none) (3)
- [x] Implement `do_pre_commit` (validate sync; stage optional later) (3)
- [x] Implement `do_audit` (summarize repo/version state; non‑destructive) (2)
- [x] Implement `do_latest_remote` (fetch remote; latest semver tag) (3)
- [x] Implement `do_remote_compare` (local vs remote semver drift) (3)
- [x] Implement `do_rbuild_compare` (build counts local vs remote) (2)
- [x] Implement `do_can_semver` readiness checks (2)
- [x] Implement `do_release` as wrapper around `promote release` (3)
- [x] Remove deprecated `snip` from dispatch (2)
- [x] Implement `do_auto` minimal behavior or hide flag (2)
- [x] Map `bcr` alias to `do_rbuild_compare` (compat wrapper) (1)
- [x] Docs: align README sync examples (type‑aware) or implement type routing (2)
- [x] Docs: update README_TEST to use `./test.sh`; remove “bc unimplemented” note (1)
- [x] Code hygiene: dedupe duplicate `do_status` definition (1)

## M8 — Baseline + Validate/Drift Hardening
- [x] Guard semv‑aware flows (bump/promote baseline requirement) (2)
- [x] Add validate/drift edge tests: no tags + package; tags only; aligned (3)
- [x] Fix drift bug: define `git_version_num` inside `do_drift()` (1)
- [x] Add `--auto` flag parsing and default `opt_auto` state (preserve current auto‑mode) (2)

## M9 — Promotion Coverage
- [x] Add tests for `promote beta` and `promote release` (3)
  - [x] Verify `latest` retagging, `vX.Y.Z-stable` snapshot creation, and `release` tagging (2)

## M10 — Remote Robustness
- [x] Use `which_main` (or remote HEAD) for remote build count (3)
- [x] Add test that doesn’t assume `origin/main` exists (2)

## M11 — Multi‑Language Sync Tests
- [x] Mixed project sync + validate test (rust/js/python) (5)

## M12 — Dispatcher Hybrid Mapping (Flagged)
- [x] Implement hybrid mapping behind feature flag (5)
- [x] Opt‑in mapping test (2)

## M13 — Pre‑commit Auto Staging (Optional)
- [x] Add optional staging path in pre‑commit (flag: --stage) (3)

## M14 — Label Scheme Alignment (SEMV v2.0)
- [x] Implement multi‑label regex for bump detection: major `(major|breaking|api)`, minor `(feat|feature|add|minor)`, patch `(fix|patch|bug|hotfix|up)`, dev `dev` (2)
- [x] Update `usage()` COMMIT LABELS section (1)
- [x] Update `semv lbl` output to new scheme (1)
- [x] Update README commit conventions to v2.0 (1)
- [x] Add a tiny test that a `fix:` commit triggers patch bump in `do_next_semver` path (2)

## M15 — Hygiene + Conventions
- [x] Confirm semantics: added optional `_safe_confirm` (env: `SEMV_SAFE_CONFIRM=1`); pseudo‑tty test TBD (3)
- [x] Options semantics: 0=true flags and QUIET/DEBUG/TRACE docs aligned (2)
- [x] XDG+ naming: document canonical `*_HOME` variables in README (2)
- [ ] Cleanup stale comments (SEM V HOME migration, etc.) (1)
- [ ] Shellcheck/shift‑guard hygiene pass (no behavior change) (3)
- [x] Remove/avoid `DEFAULT_*` options in docs (2)
- [x] Document `build.sh -r` behavior and risks in README (1)
