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
- Implement legacy‑standard commands that the dispatcher maps but are not yet implemented.
- Add targeted tests that assert expected behavior and outputs.
- Keep scope tight and leverage existing helpers to avoid duplicate logic.

### Included Commands
- Build Count: `do_build_count` (thin wrapper over `__git_build_count`)
- Mark 1: `do_mark_1` (init repo, create v0.0.1 when appropriate)
- Pre‑Commit: `do_pre_commit` (validate sync; optionally stage version files)
- Audit: `do_audit` (summarize repo/version state; non‑destructive)
- Remote Latest: `do_latest_remote` (show latest remote semver tag)
- Remote Compare: `do_remote_compare` (local vs remote semver drift)
- Remote Build Compare: `do_rbuild_compare` (compare build counts local vs remote)

### Out of scope for M7
- Push operations and network side‑effects (unless trivial and safe)
- Large refactors to tagging/remote transport

## Out of Scope (for now)
- Broad refactors that require changing all dispatched functions’ argument contracts.
- Networked/CI integration work beyond basic local validation.

## Milestone 8: Baseline + Validate/Drift Hardening
- Guard any remaining semv‑aware flows that require a baseline (ensure guidance to `mark1`/`new`).
- Add edge‑case tests for validate/drift (no tags + package; tags only; aligned state).
- Fix drift analysis bug: define `git_version_num` inside `do_drift()`.
- Add explicit `--auto` option; preserve current default auto-mode for non-interactive flows.

## Milestone 9: Promotion Coverage
- Add tests for `promote beta` and `promote release` to verify retag behavior and snapshots.
  - Verify `latest` retagging, `vX.Y.Z-stable` snapshot creation, and `release` pointing at the resolved commit.

## Milestone 10: Remote Robustness
- Use `which_main` (or remote HEAD) to determine remote default branch for build count.
- Add a test that doesn’t assume `origin/main` exists.

## Meta: IX Protocol Alignment
- Maintain IX loop: roadmap → tasks → SESSION.md log per change.
- Enforce stderr/stdout discipline and 0=true flags.
- Prefer safe, reversible fixes before refactors; RFC before invasive changes.

## Milestone 11: Multi‑Language Sync Tests
- Create a mixed project (rust/js/python) and assert sync + validate behaviors.

## Milestone 12: Dispatcher Hybrid Mapping (Flagged)
- Implement hybrid mapping behind a feature flag; default to explicit mapping.
- Add opt‑in test to validate mapping behavior.

## Milestone 13: Pre‑commit Auto Staging (Optional)
- Offer to stage version files when drift resolved or changes detected (document clearly).
