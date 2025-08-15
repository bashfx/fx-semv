# SEMV Command Reference

**Version**: 2.0.0-dev_1  
**Complete command documentation for SEMV**

## 📖 Command Syntax

```bash
semv [command] [arguments] [flags]
```

## 📋 Command Categories

- [Version Operations](#version-operations)
- [Project Analysis](#project-analysis)  
- [Synchronization](#synchronization)
- [Build Operations](#build-operations)
- [Repository Management](#repository-management)
- [Workflow Automation](#workflow-automation)
- [Lifecycle Management](#lifecycle-management)
- [Development Commands](#development-commands)

---

## Version Operations

### `semv` (default)
**Show current version**

```bash
semv
# Output: v1.2.3
```

**Usage**: 
- Default command when no arguments provided
- Outputs latest semantic version tag to stdout
- Returns 0 if version found, 1 if no semver tags

**Example**:
```bash
# Capture version in script
current_version=$(semv)
echo "Current version: $current_version"
```

---

### `semv next`
**Calculate next version (dry run)**

```bash
semv next
# Output: v1.2.4
```

**Usage**:
- Analyzes commit history since last tag
- Calculates appropriate version bump
- Does not create tags or modify anything
- Useful for CI/CD pipelines

**Example**:
```bash
# Check what the next version would be
next_version=$(semv next)
if [[ "$next_version" =~ "2.0.0" ]]; then
    echo "Major version bump detected!"
fi
```

---

### `semv bump`
**Create and push new version tag**

```bash
semv bump
```

**Usage**:
- Creates new git tag based on commit analysis
- Pushes tag to remote repository
- Handles uncommitted changes with confirmation
- Integrates with sync features if available

**Interactive Flow**:
1. Analyzes commits since last tag
2. Calculates new version
3. Prompts for confirmation if dev notes found
4. Creates annotated git tag
5. Pushes to remote
6. Syncs package files if detected

**Example**:
```bash
# Standard bump
semv bump

# Force bump without confirmations
semv -y bump

# Bump with debug output
semv -d bump
```

---

### `semv tag`
**Show latest semantic version tag**

```bash
semv tag
# Output: v1.2.3
```

**Usage**:
- Alias for default `semv` command
- Explicitly shows latest semver tag
- Filters out non-semver tags

---

## Project Analysis

### `semv info`
**Show repository and version status**

```bash
semv info
```

**Output Example**:
```
~~ Repository Status ~~
⟡ User: [qodeninja]
⟡ Repo: [my-project] [main] [main]  
⟡ Changes: [Edits +3]
⟡ Build: [1247:1245]
⟡ Last: [2 days] Today 3 hrs 15 min
⟡ Version: [v1.2.3 -> v1.2.4]

~~ Sync Status ~~
⟡ Detected sources: rust js
⟡ Sync Status: ✓ In Sync
⟡ Last sync: rust -> v1.2.3
```

**Usage**:
- Comprehensive repository overview
- Shows sync status if multi-language sources detected
- Displays build count comparison (local vs remote)
- Time analysis since last commit

---

### `semv pend [label]`
**Show pending changes since last tag**

```bash
# Show all changes
semv pend
semv pend any

# Show specific label changes
semv pend feat
semv pend fix
semv pend brk
semv pend dev
```

**Output Example**:
```
Found changes (feat) since v1.2.3:
a1b2c3d - feat: add user authentication
e4f5g6h - feat: implement file upload
```

**Usage**:
- Filters commits by message prefix
- Useful for release note generation
- Returns 0 if changes found, 1 if none

---

### `semv since`
**Time since last commit**

```bash
semv since
# Output: Last commit was Today 3 hrs 15 min
```

**Usage**:
- Human-readable time formatting
- Color-coded based on age (green < 7 days, orange < 30 days, red > 30 days)
- Useful for project activity monitoring

---

### `semv status`
**Show working directory status**

```bash
semv status
# Output: 3
```

**Usage**:
- Returns number of changed files
- Outputs count to stdout for scripting
- Returns 0 if changes exist, 1 if clean

**Example**:
```bash
if semv status > /dev/null; then
    echo "Working directory has changes"
fi
```

---

## Synchronization

### `semv sync [type]`
**Auto-detect and sync all version sources**

```bash
# Auto-detect and sync all
semv sync

# Sync specific project type
semv sync rust
semv sync js  
semv sync python
semv sync bash
```

**Usage**:
- Implements "highest version wins" model
- Updates all sources to match highest version found
- Creates backup files before modification
- Updates build cursor with sync metadata

**Process Flow**:
1. Detect project types in current directory
2. Gather versions from all sources (git tags, package files, build cursor)
3. Determine highest semantic version
4. Update all other sources to match
5. Record sync metadata in build cursor

**Example Sync**:
```bash
# Before sync:
# Git tags: v1.2.3
# Cargo.toml: version = "1.2.5"
# package.json: "version": "1.2.1"

semv sync

# After sync:
# Git tags: v1.2.5 (created)
# Cargo.toml: version = "1.2.5" (unchanged)
# package.json: "version": "1.2.5" (updated)
```

---

### `semv validate`
**Check all sources are in sync**

```bash
semv validate
```

**Output Example**:
```
✓ All sources are in sync: v1.2.3
```

**Usage**:
- Non-destructive validation
- Returns 0 if all sources match, 1 if drift detected
- Useful for CI/CD validation

---

### `semv drift`
**Show version mismatches across sources**

```bash
semv drift
```

**Output Example**:
```
Version source comparison:
⟡ Git tags: v1.2.3
⟡ Build cursor: v1.2.4-dev_2
⟡ rust: 1.2.5
⟡ js: 1.2.1
```

**Usage**:
- Diagnostic command for version conflicts
- Shows all detected version sources
- Does not modify anything

---

## Build Operations

### `semv file [filename]`
**Generate build information file**

```bash
# Default filename (build.inf)
semv file

# Custom filename
semv file version.txt

# Use build directory
semv -B file
```

**Generated Content**:
```bash
DEV_VERS=v1.2.3
DEV_BUILD=1247
DEV_BRANCH=main
DEV_DATE=08/15/25
DEV_SEMVER=v1.2.4-dev_2
SYNC_SOURCE=rust
SYNC_VERSION=1.2.3
SYNC_DATE=2025-08-15T10:30:00Z
```

**Usage**:
- Creates build metadata for CI/CD
- Automatically generated during sync operations
- Can be disabled with `--no-cursor` flag

---

### `semv bc`
**Show current build count**

```bash
semv bc
# Output: 1247
```

**Usage**:
- Based on git commit count + minimum build floor
- Useful for CI build numbering
- Outputs number to stdout for scripting

---

## Repository Management

### `semv new`
**Initialize repository with v0.0.1**

```bash
semv new
```

**Usage**:
- Creates initial semver tag v0.0.1
- Must be run on main/master branch
- Creates README.md if it doesn't exist
- Prompts to push to remote

**Interactive Flow**:
1. Checks if already has semver tags
2. Validates on main branch
3. Creates/stages README.md
4. Creates initial commit
5. Creates v0.0.1 annotated tag
6. Prompts to push to origin

---

### `semv can`
**Check if repository can use semver**

```bash
semv can
```

**Output Example**:
```
✓ Can use semver here. Repository found.
⟡ Use 'semv new' to set initial v0.0.1 version
⟡ Current branch: main
```

**Usage**:
- Diagnostic command for semver readiness
- Checks git repository status
- Provides guidance for initialization

---

### `semv fetch`
**Fetch remote tags**

```bash
semv fetch
```

**Usage**:
- Fetches tags from remote repository
- Reports if new tags were found
- Useful before version operations

---

## Workflow Automation

### `semv pre-commit`
**Pre-commit validation hook**

```bash
semv pre-commit
```

**Usage**:
- Validates version sync status
- Checks for unstaged version files
- Can auto-stage version files with confirmation
- Returns 0 if ready to commit, 1 if issues found

**Integration Example**:
```bash
# .git/hooks/pre-commit
#!/usr/bin/env bash
semv pre-commit
```

---

### `semv release`
**Full release workflow**

```bash
semv release
```

**Process Flow**:
1. Runs pre-commit validation
2. Performs sync if needed
3. Calculates and creates new version
4. Updates all package files
5. Pushes to remote
6. Shows final status

**Usage**:
- One-command release process
- Integrates all SEMV features
- Suitable for automated releases

---

## Lifecycle Management

### `semv install`
**Install to BashFX system**

```bash
semv install
```

**Actions**:
- Copies script to `~/.local/lib/fx/semv/`
- Creates symlink in `~/.local/bin/semv`
- Sets up configuration directories
- Creates default configuration files
- Creates session RC file

---

### `semv uninstall`
**Remove from system**

```bash
semv uninstall
```

**Actions**:
- Removes binary symlink
- Removes library directory  
- Prompts to remove configuration
- Prompts to remove data directory

---

### `semv reset`
**Reset configuration to defaults**

```bash
semv reset
```

**Actions**:
- Backs up existing configuration
- Recreates default configuration
- Recreates RC file
- Preserves data directory

---

### `semv status` (installation)
**Show installation status**

```bash
semv status
```

**Output Example**:
```
SEMV Installation Status:
✓ Binary: ~/.local/bin/semv ✓
✓ Library: ~/.local/lib/fx/semv ✓  
✓ Configuration: ~/.local/etc/fx/semv ✓
✓ Data: ~/.local/data/fx/semv ✓
✓ RC File: ~/.local/fx/semv/.semv.rc ✓
```

---

## Development Commands

### `semv inspect`
**Show available functions and dispatch mappings**

```bash
semv inspect
```

**Usage**:
- Lists all `do_*` functions
- Shows dispatch table mappings
- Useful for development and debugging

---

### `semv lbl`
**Show commit label conventions**

```bash
semv lbl
```

**Output**:
```
~~ SEMV Commit Labels ~~
⟡ brk:  -> Breaking changes [Major]
⟡ feat: -> New features [Minor]  
⟡ fix:  -> Bug fixes [Patch]
⟡ dev:  -> Development notes [Dev Build]
```

---

### `semv help`
**Display help information**

```bash
semv help
semv -h
semv ?
```

**Usage**:
- Shows comprehensive usage information
- Lists all commands and flags
- Provides examples and workflows

---

## 🚩 Global Flags

All commands support these flags:

### Logging & Output
| Flag | Description | Example |
|------|-------------|---------|
| `-d` | Enable debug messages | `semv -d info` |
| `-t` | Enable trace messages | `semv -t bump` |
| `-q` | Quiet mode (errors only) | `semv -q sync` |
| `-D` | Master dev flag (enables -d, -t) | `semv -D release` |

### Behavior Control
| Flag | Description | Example |
|------|-------------|---------|
| `-f` | Force operations | `semv -f bump` |
| `-y` | Auto-answer yes to prompts | `semv -y new` |
| `--no-cursor` | Disable .build file creation | `semv --no-cursor file` |

### Build Options
| Flag | Description | Example |
|------|-------------|---------|
| `-N` | Enable dev note mode | `semv -N bump` |
| `-B` | Use ./build/ directory | `semv -B file` |

---

## 🔗 Command Chaining Examples

### Typical Development Workflow
```bash
# Check status and sync
semv info
semv validate || semv sync

# Make changes, commit, and release
git add .
git commit -m "feat: add new feature"
semv bump

# Generate build file for CI
semv file
```

### CI/CD Integration
```bash
# Validation pipeline
semv validate
semv pre-commit

# Release pipeline  
semv bump
semv file
```

### Multi-Project Maintenance
```bash
# Check all project types
semv drift

# Sync specific language
semv sync rust

# Full release with all checks
semv release
```

---

## 📊 Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error or operation failed |

**Note**: SEMV follows standard Unix conventions for exit codes. Check the return value for scripting purposes.

---

**SEMV v2.0** - Complete command reference for semantic version management 🚀