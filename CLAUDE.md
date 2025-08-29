# CLAUDE.md - Project Context & Workflow

## Important Note

## Project Context Discovery

You're likely continuing a previous session. Follow this sequence to understand the current state:

### 1. Read Documentation (in priority order)

Use case-insensitive search. Check project root, `doc*` directories, and `locker/docs_sec`:

**a. Directives & Rules**
- `IX*.md` (instructions/directives)  
- `AGENTS.md` (standardized directives)

**b. Tasks & Continuations**
- `*TODO*.md` (pending tasks)
- `*SESSION*.md` or `PLAN.md` (previous session notes)

**c. Architecture**
- `ARCH*.md`, `BASHFX*.md`
- `*ref*\patterns`: standarized patterns or styles
- `*ref*.md` : reference files for desired patterns, strategies, etc.
- Internal architectures: BashFX (v2.1), REBEL/RSB (Rust DSL)

**d. Project Concepts**
- `*CONCEPT*.md`, `*PRD*.md`, `*BRIEF*.md`

**e. Code & References**
- `src/` (Rust), `parts/` (BashFX using the build.sh pattern)
- Legacy/reference files (`.txt`, `*ref*` folders)

### 2. Plan Execution

1. **Analyze** key files to determine next tasks
2. **Create/Update** `PLAN.md` with milestones and story points (≤1 point per subtask)
3. **Share** high-level plan with user for approval

### 3. Development Workflow

**Branch Management**
- Create new branch: `feature/name-date`, `refactor/name-date`, or `hotfix/name-date`
- Use alternate name if branch exists

**Task Execution**
- Small tasks: iterate freely
- Complex/critical changes: require verification
- All code needs verifiable tests via `test_runner.sh` (for bash)
- Tests must not regress previous functionality

**Milestone Completion**
- All work must have passing tests
- User verifies success
- Check in with semv prefix (`semv lbl` for options) no branding!
- Manually bump versions in project files
- Merge to main and push to origin

## Available Tools

**`func`** - Shell script source code analysis
- `func ls <src>` - list functions
- `func spy <name> <src>` - extract specific function

**`gitsim`** - Virtual git environment (don't use on gitsim project itself)

Use `<cmd> help` for detailed APIs.

- Report any tool problems immediately.
