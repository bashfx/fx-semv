

# IX - Automation Protocol 

This protocol enables another AI to understand a BashFX project, determine its state, devise a plan, and iterate with consistent artifacts and safety across diverse projects (without assuming any specific problem domain like git, packaging, etc.).


USER NOTES: if you have any refining questions, please ask them . otherwise you may continue your ix
  automation protocol as planned. Start with the roadmap generation, tasks etc. Then execute
  one at a time while updating your SESSION.md for each progression. I may from time to time
  ask questions or provide new context, but this should not interrupt your flow unless it is a
   critical insight, in which case you may consider its priority in the roadmap, and breaking
  down the new implied related tasks as needed; if its not high priority you can add it later,
   in any case always at least add to roadmap any new implied tasks or changes in case they
  are not properly triaged

## 1) Understand The Project
- Read: `README.md`, `docs/` (architecture, concepts, commands, test alignment), ADRs if any.
- Explore structure: `rg --files` `find` `ls`; focus on `parts/`, `build.sh`, `tests/`, lifecycle modules.
- Identify entry script and assembly flow.
- Note any repo conventions and non-standard patterns.

Outputs:
- Short summary: purpose, entry points, key modules, unusual constraints.

## 2) Determine Project State
- Build status: if `build.sh` exists, run `./build.sh -c && ./build.sh`; otherwise identify the build/assembly process, then `bash -n <main-script>.sh`.
- Test harness: discover `tests/` or `test/`; add `tests/test.sh` if missing.
- XDG+ compliance: ETC/DATA dirs, RC/state location; presence of legacy HOME-era paths.
- Standards: stderr vs stdout, function ordinality, 0=true flag semantics, color assumptions.
- Known issues: scan TODO/ISSUES/SESSION; grep for obvious pitfalls.

Outputs:
- “State snapshot” bullets: build/tests/paths/standards/defects.

## 3) Devise A Plan
- Classify changes:
  - Safe fixes: low-risk corrections (help text, tag correctness, path aliases, doc links).
  - Structural: config consolidation, test alignment, helper extraction.
  - Invasive: dispatcher refactors, signature changes; require RFC.
- Sequence by value and risk; prefer safe fixes first.

Outputs:
- ROADMAP.md: 5–7 milestones, outcome-focused, reversible where possible.

## 4) Create Story Tasks
- Break milestones into point-sized stories (1,2,3,5) in TASKS.md.
- Each task specifies intent, scope (files/modules), exit criteria, and risks.
- Keep the list living; mark [x] as completed.

Outputs:
- TASKS.md with prioritized, verifiable tasks.

## 5) Iterate With User Adjustments
- Loop for each task:
  1. Announce intent (one sentence).
  2. Edit; keep changes small and scoped.
  3. Build and syntax check.
  4. Validate specific behavior; run `./tests/test.sh health` if available.
  5. Log in `SESSION.md`: what changed, why, next.
- Prefer helpers over code duplication; avoid paradigm shifts without inventory/RFC.

Outputs:
- SESSION.md entries with rationale and next actions.

## 6) Testing Alignment
- Add `tests/test.sh` dispatcher with `list | run [pattern] | health` if missing.
- Discover both `tests/` (preferred) and `test/` (legacy); migrate gradually.
- Follow KB testing style: ceremony output, virtualization as appropriate, XDG cache paths, `-y` for automation.

Outputs:
- Executable dispatcher; green syntax health; minimal ceremony suitable for CI/local.

## 7) Safe Fixes Pattern (General)
- Deterministic references: when binding names to resources (files, services, versions, IDs), resolve the intended target explicitly; avoid implicit/global defaults that may drift (e.g., “current”, “latest”, working directory assumptions).
- Path normalization: standardize configuration/data locations to the project’s conventions (for BashFX, prefer XDG+); keep legacy aliases during migration.
- State file placement: store ephemeral/session state in the canonical runtime location; provide a migration helper from legacy locations and call it in install/status/startup flows.
- UX coherence: correct help text, flags, and outputs to match actual behavior; maintain stderr for messages and stdout for values.
- Documentation alignment: ensure README and docs reflect reality (architecture version, file layout, commands) and link to actual in-repo documents.

## 8) Quick Start (New Repo)
- Create `ROADMAP.md`, `TASKS.md`, `SESSION.md`.
- Search for anti‑patterns to stabilize early:
  - Hardcoded temp paths: `rg -n "\b/tmp\b|mktemp -p /tmp"`
  - Implicit globals/defaults: `rg -n "latest|current|HEAD|pwd\)"`
  - Mixed streams: `rg -n "echo .* >[^&]|1>&2|>&1"`
- Add `<PROJECT>_ETC`; move RC/state to canonical location; add migration.
- Add `tests/test.sh` (or minimal runner); implement `list|run|health`.
- Build, syntax check, and document changes succinctly.
