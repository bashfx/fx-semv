# RFC: Dispatcher Lazy-Vars Refactor

## Summary
Evaluate migrating the dispatcher to a lazy-vars pattern with safer argument handling while maintaining compatibility. The goal is to reduce mapping boilerplate where appropriate, without breaking existing `do_*` signatures.

## Current State
- Explicit `case` mapping from `cmd` → `do_*` with `func_name`.
- Dispatcher shifts the first two args and invokes target with a fixed arity of `"$arg" "$arg2" "$@"`.
- Many `do_*` functions have variable arities and rely on current shifting behavior.

## Options
1. Status Quo (No Change)
   - Keep explicit mapping; minimal risk; no gains.

2. Hybrid Mapping (Recommended)
   - Keep explicit `case` for safety and aliases.
   - Derive `func="do_${cmd}"` only for 1:1 routes after a whitelist check (`declare -F`).
   - Preserve current shifting behavior to avoid breaking arg contracts.
   - Add a feature flag to disable derived mapping if issues arise.

3. Full Lazy-Args Refactor
   - No shifting in dispatcher; pass `"$@"` untouched to `do_*`.
   - Requires surveying every `do_*` signature and updating call sites.
   - Highest risk; larger payoff in simplicity and predictability.

## Survey (Current Repository)
Discovered `do_*` functions:
```
do_bump, do_info, do_pending, do_last, do_status, do_fetch_tags, do_tags,
do_inspect, do_label_help, do_auto, do_since_pretty, do_days_ago, do_sync,
do_compare_versions, do_is_greater, do_test_semver, do_get, do_get_all,
do_set, do_set_all, do_latest_tag, do_latest_semver, do_change_count,
do_next_semver, do_build_file, do_install, do_uninstall, do_reset, do_status,
do_retag, do_promote, do_promote_to_beta, do_promote_to_stable,
do_promote_to_release, do_hook, do_drift, do_validate
```
Signatures vary, some expect positional `$1 $2`, others parse `$@`.

## Plan
- Phase 0: Add RFC file (this document) and feature flag skeleton (no behavior changes).
- Phase 1: Add optional derived mapping behind a guard: enable only if `declare -F do_${cmd}` and `cmd` in allowlist; otherwise use explicit mapping.
- Phase 2: Observe and document any incompatibilities; consider moving to no-shift model in a future major iteration.

## Risks
- Silent behavior changes if argument contracts shift.
- Aliases might bypass derived mapping unless accounted for.

## Decision
Proceed with Option 2 (Hybrid Mapping) only after explicit approval; current phase ends with documentation and survey.

