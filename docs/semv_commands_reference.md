# SEMV Command Reference

DEPRECATION NOTICE: This reference may be out of date. Prefer `README.md` for current usage and `semv.sh` `usage()` output. Planning/status lives in `ROADMAP.md` and `TASKS.md`.

**Version**: 2.0.0-production  
**Updated**: 2025-08-26  
**Complete command documentation for SEMV v2.0**

## Command Syntax

```bash
semv [command] [arguments] [flags]
```

## Version Operations

### `semv` (default)
**Show current semantic version**
```bash
semv                    # Output: v1.2.3
current=$(semv)         # Capture for scripts
```

### `semv next`
**Calculate next version (dry run)**
```bash
semv next               # Output: v1.2.4-dev_2
semv next --dev         # Include dev suffix
```

### `semv bump [TYPE]`
**Create new version tag**
```bash
semv bump               # Auto-detect bump type
semv bump major         # Force major bump
semv bump minor         # Force minor bump  
semv bump patch         # Force patch bump
semv bump --dev         # Enter/continue dev mode
```

**Major Bump Ceremony**:
```
🎉 MAJOR BUMP DETECTED! 🎉
⚠️  You're about to introduce BREAKING CHANGES
🏗️  Auto-cleanup will remove old patch tags
🚀 Ready for the responsibility? [y/N]
```

## Version Information & Analysis

### `semv get TYPE [FILE]`
**Extract version from package files**
```bash
semv get rust           # Show Cargo.toml version
semv get js             # Show package.json version
semv get python         # Show pyproject.toml version
semv get bash ./script.sh # Show version from bash file
semv get all            # Show all version sources
```

### `semv set TYPE VERSION [FILE]`
**Update version in package files**
```bash
semv set rust 1.2.3     # Update Cargo.toml
semv set js 1.2.3        # Update package.json
semv set python 1.2.3    # Update pyproject.toml
semv set bash 1.2.3 ./script.sh # Update bash file
semv set all 1.2.3       # Update all detected packages
```

### `semv info`
**Show repository status and version analysis**
```bash
semv info               # Comprehensive project status
```

### `semv status`
**Show current version state and drift**
```bash
semv status             # Version alignment status
```

## Conflict Resolution & Synchronization

### `semv sync`
**Resolve version conflicts between sources**
```bash
semv sync               # Interactive conflict resolution
semv sync --auto        # Auto-resolve silently
```

### `semv drift`
**Analyze version mismatches**
```bash
semv drift              # Show version drift between sources
```

## Tag Management & Promotion

### `semv promote CHANNEL [VERSION]`
**Promote version through release channels**
```bash
semv promote beta       # dev → beta (latest-dev tag)
semv promote stable     # beta → stable (latest tag + snapshot)
semv promote release    # stable → public (release tag)
```

**Tag Lifecycle Flow**:
```
Development: v1.2.3-dev_N  → retags 'dev' continuously
Exit Dev:    v1.2.4        → retags 'latest-dev' 
Stabilize:   v1.2.4        → retags 'latest' + creates 'v1.2.4-stable'
Publicize:   v1.2.4        → retags 'release' (manual)
```

### `semv retag`
**Auto-retag special tags (legacy compatibility)**
```bash
semv retag              # Retag based on current version state
```

## Hook Management

### `semv hook TYPE [ACTION] [COMMAND]`
**Manage version bump hooks**
```bash
semv hook major         # Show current major hook
semv hook major set "./release.sh"  # Set major bump hook
semv hook major stub    # Generate hook template
semv hook minor remove  # Remove minor hook
```

**Supported Hook Types**: `major`, `minor`, `patch`, `dev`

**Hook Execution**: Hooks run automatically after successful version bumps with arguments `$1=new_version $2=previous_version`

## Project Analysis

### `semv last`
**Show last commit information**
```bash
semv last               # Time since last commit with status
```

### `semv pend [LABEL]`
**Show pending changes since last tag**
```bash
semv pend               # Show all pending changes
semv pend dev           # Show pending dev: commits
```

### `semv tags`
**List all repository tags**
```bash
semv tags               # List all git tags
```

## Build Operations

### `semv file [NAME]`
**Generate build information file**
```bash
semv file               # Create .build file
semv file build.inf     # Custom filename
semv file --no-cursor   # Skip cursor generation
```

## Repository Management

### `semv can`
**Check if repository is ready for semver**
```bash
semv can                # Validate semver readiness
```

### `semv new`
**Initialize repository for semver**
```bash
semv new                # Create initial v0.0.1 tag
```

### `semv mark1`
**First-time registration (baseline)**
```bash
semv mark1              # Create sync tag from package version, or v0.0.1 if none
```

### `semv fetch`
**Fetch remote tags**
```bash
semv fetch              # Update local tags from remote
```

### Remote operations
```bash
semv remote             # Show latest remote semver tag (origin)
semv upst               # Compare local vs remote semver tag
semv rbc                # Compare local vs remote build counts
```

## Workflow Integration

### `semv auto PATH [COMMAND]`
**Automated mode for external tools**
```bash
semv auto . fwd         # Check for forward changes
semv auto . chg         # Check for any changes
```

## Development Commands

### `semv inspect`
**Show available functions and mappings**
```bash
semv inspect            # List internal functions
```

### `semv lbl`
**Show commit label help**
```bash
semv lbl                # Display commit label reference
```

## Commit Label System

**SEMV v2.0 uses the following commit labels (Breaking Change)**:

### Major Bumps (Ceremonious)
```bash
major: API redesign           # Explicit major changes
breaking: Remove deprecated   # Breaking changes
api: Change function sig      # API-level changes
```

### Minor Bumps (Auto-tag)
```bash
feat: Add user auth          # New features
feature: Implement search    # Feature additions  
add: New configuration       # Adding functionality
minor: Explicit minor bump   # Manual minor bump
```

### Patch Bumps (Manual tag only)
```bash
fix: Resolve login bug       # Bug fixes
patch: Security update       # Explicit patches
bug: Fix memory leak         # Bug-specific fixes
hotfix: Critical prod fix    # Urgent fixes
up: Update documentation     # Simple updates
```

### Development State
```bash
dev: WIP authentication      # Broken/development state
```

**Patch Tag Management**: 
- Patch versions require manual tagging (`semv bump patch`)
- Old patch tags auto-cleaned after minor/major bumps (keep last 3)
- Special tags preserved: `rc`, `alpha`, `beta`, `dev`, `build`, `-stable`

## Global Flags

```bash
-d, --debug     Enable debug output
-t, --trace     Enable trace output  
-D, --debug-master  Enable master debug mode
-y, --yes       Auto-confirm all prompts
-N, --dev       Enable dev mode for bumps
--auto          Silence ceremony prompts
```

## Environment Variables

### Safety Flags
```bash
SEMV_MINOR_AUTO_SAFE=1    # Disable minor auto-catchup
SEMV_MAJOR_AUTO_SAFE=1    # Disable major auto-catchup
SEMV_ALL_AUTO_SAFE=1      # Disable all auto-catchup
NO_BUILD_CURSOR=1         # Disable build cursor generation
```

### Hook Configuration (via .semvrc)
```bash
SEMV_MAJOR_BUMP_HOOK="./scripts/major_release.sh"
SEMV_MINOR_BUMP_HOOK="./scripts/minor_release.sh"
BASH_VERSION_FILE="./my-tool.sh"  # Which bash file to track
```

## Examples

### Development Workflow
```bash
# Normal development
semv bump minor                   # v1.2.0 → v1.3.0

# High-iteration development (broken state)  
semv bump --dev                   # v1.3.0 → v1.3.1-dev_1
semv bump --dev                   # Multiple iterations...
semv bump --dev                   # v1.3.1-dev_5

# Exit dev mode
semv bump                         # Prompt: beta or stable?
# → beta: v1.3.1, retags 'latest-dev'
# → stable: v1.3.1, retags 'latest' + 'v1.3.1-stable'

# Public release
semv promote release              # Retags 'release'
```

### Multi-Language Synchronization
```bash
# Check version alignment
semv get all                      # Show all package versions
semv drift                        # Show version conflicts

# Resolve conflicts
semv sync                         # Interactive resolution
semv set all $(semv next)         # Align all to next version
```

### Hook-Driven Automation
```bash
# Configure hooks
semv hook major set "./release-major.sh"
semv hook minor set "./release-minor.sh"

# Hooks execute automatically
semv bump major                   # Runs major hook after tagging
```

## Migration from SEMV 1.x

### Breaking Changes in v2.0
1. **Commit Labels Changed**: `feat:` now means minor (was major), `brk:` removed  
2. **New Commands**: `get`, `set`, `sync`, `promote`, `hook` command families added
3. **Tag Retagging**: Automatic retagging of `dev`, `latest-dev`, `latest`, `release` (tags point to the resolved commit for the specified version; no implicit HEAD tagging)
4. **Patch Behavior**: Patch bumps are manual only, no auto-tagging

### Migration Steps
1. Update commit message conventions to new label system
2. Configure `.semvrc` for bash file tracking if needed  
3. Test version detection: `semv get all`
4. Resolve any version drift: `semv sync`

## Troubleshooting

### Common Issues

**"No supported project types detected"**
```bash
# Solution: Add version metadata to files
echo '# semv-version: 1.0.0' >> my-script.sh  # Bash
# Or ensure Cargo.toml/package.json has version field
```

**"Version drift detected"**  
```bash
# Check what's out of sync
semv drift
# Auto-resolve
### `semv bc`
**Show current build count (commit count + floor)**
```bash
semv bc                   # Prints numeric build count
```
semv sync
```

**"Multiple project types detected but they conflict"**
```bash  
# Configure .semvrc for multi-language projects
echo 'BASH_VERSION_FILE="./tool.sh"' > .semvrc
semv sync
```

---

**SEMV v2.0** - Production-ready semantic versioning with intelligent conflict resolution
### `semv pre-commit`
**Validate before committing**
```bash
semv pre-commit         # Fails when validation fails (e.g., drift)
```

### `semv audit`
**Summarize repository and version state**
```bash
semv audit              # Non-destructive audit of current state
```
