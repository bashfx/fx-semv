# SEMV Roadmap

This roadmap reflects the near-term path to align SEMV with BashFX v3 architecture and your clarified standards. Milestones are incremental and safety‑biased to avoid breaking changes.

## Milestone 1: Docs + Safe Fixes (Current)
- Rename semantics: document `SEMV_ETC` as the canonical name (alias `SEMV_CONFIG` remains for now).
- Fix tag retagging to reference the correct commit (not HEAD).
- Correct `build.sh` help text (`-o` default to `semv.sh`).
- Add ROADMAP.md, TASKS.md, and start SESSION.md updates.

## Milestone 2: Config Path Consolidation
- Introduce `SEMV_ETC` in code as primary; keep `SEMV_CONFIG` as a backwards‑compatible alias.
- Move `.semv.rc` to `${SEMV_ETC}`; migration logic if old file exists in prior location.
- Update status/install flows to reference `SEMV_ETC` consistently.

## Milestone 3: Test Alignment (KB Pattern)
- Create `tests/test.sh` dispatcher with ceremony and category filters.
- Migrate current `test/` → `tests/` and port to gitsim/XDG cache pattern.
- Add suite health checks (syntax, discovery, basic run path).

## Milestone 4: Redundancy Reduction
- Identify repeated patterns (git tag ops, printer wrappers, guard checks) and consolidate into helpers without changing behavior.
- Keep function ordinality and stderr/stdout rules intact.

## Milestone 5: Documentation Sync
- Update README to BashFX v3, fix outdated links, and add a brief compliance checklist.
- Cross‑verify Semv docs match implemented behavior (promote flows, sync policy, paths).

## Milestone 6: Deferred Paradigm Review
- Dispatcher lazy‑vars refactor (evaluate risks, inventory all `do_*` signatures, design an opt‑in migration plan).
- Decide whether to keep direct mapping (safer) or introduce derived mappings with hardened guards.

## Milestone 7: Command Surface Completion
- Implement dispatcher‑mapped commands and align help/docs with code.
- Add targeted tests that assert expected behavior and outputs.
- Keep scope tight and leverage existing helpers to avoid duplicate logic.

### Command Surface Status
- [x] Build Count: `do_build_count` (via `__git_build_count`)
- [x] Mark 1: `do_mark_1` (baseline tag from packages or v0.0.1)
- [x] Pre‑Commit: `do_pre_commit` (validate sync; guard drift)
- [x] Audit: `do_audit` (summarize repo/version state; non‑destructive)
- [x] Remote Latest: `do_latest_remote`
- [x] Remote Compare: `do_remote_compare`
- [x] Remote Build Compare: `do_rbuild_compare` (CLI: `rbc`)
- [x] Can: `do_can_semver` (add lightweight readiness checks)
- [x] Release: `do_release` (wrapper around `promote release`)
- [x] Snip: removed from dispatch (deprecated)
- [x] Auto: `do_auto` (implement minimal mode)
- [x] Alias: map `bcr` → `do_rbuild_compare` (compat wrapper)
- [x] Docs: align README “sync TYPE” examples (global sync)

### Out of scope for M7
- Push operations and network side‑effects (unless trivial and safe)
- Large refactors to tagging/remote transport

## Out of Scope (for now)
- Broad refactors that require changing all dispatched functions’ argument contracts.
- Networked/CI integration work beyond basic local validation.

## Milestone 8: Baseline + Validate/Drift Hardening
- [x] Guard semv‑aware flows that require a baseline (bump/promote guard; `baseline_guard.sh`)
- [x] Edge‑case tests for validate/drift (no tags + package; tags only; aligned state)
- [x] Fix drift analysis bug: define `git_version_num` inside `do_drift()`
- [x] Add explicit `--auto/--no-auto` option; preserve current default auto‑mode

## Milestone 9: Promotion Coverage
- [x] Tests for `promote beta` and `promote release` (retag behavior and snapshots)
  - Verify `latest` retagging, `vX.Y.Z-stable` snapshot creation, and `release` pointing at the resolved commit.

## Milestone 10: Remote Robustness
- [x] Use `which_main` (or remote HEAD) for remote default branch
- [x] Test for non‑`main` default (e.g., `trunk`) via `remote_head_build_count.sh`

## Meta: IX Protocol Alignment
- Maintain IX loop: roadmap → tasks → SESSION.md log per change.
- Enforce stderr/stdout discipline and 0=true flags.
- Prefer safe, reversible fixes before refactors; RFC before invasive changes.

## Milestone 11: Multi‑Language Sync Tests
- [x] Create a mixed project (rust/js/python) and assert sync + validate behaviors.

## Milestone 12: Dispatcher Hybrid Mapping (Flagged)
- [x] Implement hybrid mapping behind a feature flag (`SEMV_FEATURE_HYBRID=1`); default remains explicit mapping.
- [x] Add opt‑in test (`tests/hybrid_dispatch_optin.sh`).

## Milestone 13: Pre‑commit Auto Staging (Optional)
- [x] Offer to stage version files when aligned (flag: --stage) and document usage.

## Milestone 14: Label Scheme Alignment (SEMV v2.0)
- [x] Implement multi‑label patterns for bump detection (major/minor/patch/dev)
- [x] Update help surfaces (`usage()`, `lbl`) to reflect new scheme
- [x] Align README commit conventions to v2.0
- [x] Add a smoke test: a `fix:` commit triggers patch bump in `do_next_semver`
