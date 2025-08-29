# SEMV Core Concepts & Patterns
**Version**: 2.0.0  
**Date**: 2025-08-26  

## Philosophy

SEMV operates as an intelligent version resolution system that reconciles multiple sources of truth while respecting project-specific constraints. It prioritizes authoritative package files over commit message counting, but provides sophisticated catch-up and synchronization mechanisms.

## Core Concepts

### Version Sources & Authority Hierarchy

**Authoritative Sources** (in order of precedence):
1. **Package Files**: `Cargo.toml`, `package.json`, `pyproject.toml`, bash meta-comments
2. **Git Tags**: Semantic version tags in repository
3. **Semv Calculations**: Commit message analysis and build cursors

**Resolution Principle**: When conflicts arise, defer to the highest authoritative version, then provide user-controlled catch-up mechanisms.

### Commit Label System

**Mental Model Alignment (Breaking Change - No Backward Compatibility)**:
```bash
# Administrative/documentation work  
up: README.md updates, doc fixes          → patch (manual tag only)

# Development state markers
dev: broken state, debugging, iteration   → special (retags 'dev' continuously)

# Functional changes
fix: bug fixes, hotfixes                 → patch (manual tag only)  
patch: explicit patch bumps              → patch (manual tag only)
bug: bug-specific fixes                  → patch (manual tag only)
hotfix: urgent production fixes          → patch (manual tag only)

feat: new features, additions            → minor (auto-tag enabled)
feature: explicit feature additions      → minor (auto-tag enabled)
add: adding new functionality            → minor (auto-tag enabled) 
minor: explicit minor bumps             → minor (auto-tag enabled)

major: breaking changes, API changes     → major (ceremonious + cleanup)
breaking: explicit breaking changes      → major (ceremonious + cleanup)
api: API-level changes                   → major (ceremonious + cleanup)
```

**Complete Migration**: No support for old `brk:` or `feat:`=major paradigm.

### Tag Management Philosophy

**Tag Lifecycle States**:
- **`dev`**: Broken/debugging state, high-iteration development, continuously retagged
- **`latest-dev`**: Dev-stable state (your "beta" - fixed obvious defects, may have edge cases)  
- **`latest`**: Latest working version (stable for your tools, may not be ready for everyone)
- **`release`**: Public release ready (manually promoted, ready for wide consumption)

**Patch Tag Pollution Control**: 
- Manual tagging only (`semv bump patch` required)
- Auto-cleanup after minor/major bumps (keep last 3 patches maximum)
- Preserve special tags (`rc`, `alpha`, `beta`, `dev`, `build`, `-stable` snapshots)

**Major Bump Ceremony**:
```bash
🎉 MAJOR BUMP DETECTED! 🎉
⚠️  You're about to introduce BREAKING CHANGES
🏗️  Auto-cleanup will remove old patch tags  
🚀 Ready for the responsibility? [y/N]
```
- Explicit user confirmation required (unless `--auto` flag)
- Auto-cleanup warnings and consequences
- Can be silenced for automation

**Stable Snapshots**: 
- `v1.2.4-stable` tags created automatically on stabilization
- Provide reversion points for rollback scenarios
- Independent of retagging system

### Build System Independence

**Build Counter**: 
- Raw incremental number starting from 1000
- Never resets, always increments
- Derived from git commit history
- Independent of semantic versioning

**Build Markers**:
```bash
build:feature-x    # Historical marker for reversion
build:release-candidate  # Special build state
```

### Version Resolution Patterns

#### Pattern 1: Version Drift Detection
```
Package: v1.5.0
Git Tag: v1.2.3  
Semv Count: v1.7.0 (from commits)

Resolution: Defer to package (v1.5.0), create sync tag, warn about drift
```

#### Pattern 2: Stale Package Detection  
```
Package: v1.2.0
Git Tag: v1.5.0
Semv Count: v1.5.2

Resolution: Prompt to update package file to v1.5.0, continue from there
```

#### Pattern 3: Over-enthusiastic Counting
```
Package: v1.2.0  
Git Tag: v1.2.0
Semv Count: v1.5.0 (lots of feat: commits)

Resolution: "Semv got happy" - defer to authoritative v1.2.0, create sync tag
```

### Multi-Language Project Handling

**Embedded Packages** (same project):
- Rust + JS + Python + Bash → sync all versions
- Single source of truth across all package files
- `semv set all 1.2.3` updates everything

**Submodules** (discrete components):
- Independent versioning allowed  
- Parent project may want different child versions
- Error only on explicit conflicts, not mere presence

### Environment Safety System

**Auto-Catchup Protection**:
```bash
export SEMV_MINOR_AUTO_SAFE=1    # Disable minor auto-catchup
export SEMV_MAJOR_AUTO_SAFE=1    # Disable major auto-catchup  
export SEMV_ALL_AUTO_SAFE=1      # Disable all auto-catchup
```

**Use Case**: CI/CD environments where version bumps trigger expensive operations.

### Hook System Architecture

**Per-Project Hooks** (via `.semvrc`):
```bash
# .semvrc example
SEMV_MINOR_BUMP_HOOK="./scripts/publish_minor.sh"
SEMV_MAJOR_BUMP_HOOK="./scripts/breaking_release.sh"
BASH_VERSION_FILE="./my-tool.sh"  # Which bash file to track
```

**Hook Commands**:
```bash
semv hook major                    # Display current hook
semv hook major "./release.sh"    # Set hook command  
semv hook major --stub             # Generate template
```

### Dev Mode Workflow Integration

**Development Lifecycle**:
```bash
# Normal development (working state)
semv bump minor              # v1.2.0 → v1.3.0, retags 'latest'

# Enter dev mode (something broken, high iteration needed)  
semv bump --dev              # v1.3.0 → v1.3.1-dev_1, retags 'dev'
# Multiple iterations fixing the issue...
semv bump --dev              # v1.3.1-dev_5, retags 'dev'

# Exit dev mode (defects fixed, ready for broader testing)
semv bump                    # Prompts: "Exit dev mode to beta or stable?"
# → Choose beta: v1.3.1-beta, retags 'latest-dev' (your beta channel)
# → Choose stable: v1.3.1, retags 'latest' + creates 'v1.3.1-stable'

# Manual promotion to public (when ready for everyone)
semv promote release v1.3.1  # Retags 'release', ceremonious confirmation
```

**Dev Mode Characteristics**:
- Prevents normal version bumping (locks to dev iterations)
- Continuously retags `dev` to track current broken state  
- Warning prompts when trying to bump without `--dev` flag
- Exit requires user decision: beta testing vs direct stabilization

## Usage Patterns

### Version Inspection
```bash
# Single source inspection  
semv get rust                     # Show Cargo.toml version
semv get bash ./script.sh         # Show version from bash file
semv get js                       # Show package.json version

# Comprehensive overview
semv get all                      # All sources: package, tags, builds
```

### Version Synchronization
```bash  
# Update individual sources
semv set rust 1.2.3              # Update Cargo.toml
semv set js 1.2.3                 # Update package.json
semv set bash ./script.sh 1.2.3   # Update bash meta-comment

# Bulk synchronization
semv set all 1.2.3                # Update all detected package files
```

### Conflict Resolution Workflow
```bash
# 1. Detection
semv status                       # Shows version drift
semv drift                        # Detailed conflict analysis

# 2. Resolution  
semv sync                         # Auto-resolve with prompts
semv sync --auto                  # Auto-resolve silently
semv sync --catch-up minor        # Resolve + catch up minor versions
```

### Development Workflow Integration
```bash
# Standard development
semv bump minor                   # Normal feature bump
semv bump fix                     # Manual patch bump

# High-iteration development (broken state)
semv bump --dev                   # Enter/continue dev mode
semv status                       # Check current dev state

# Exit dev mode  
semv bump                         # Prompted: beta or stable?
semv promote beta                 # Explicit beta promotion
semv promote stable               # Explicit stable promotion

# Publishing workflow
semv promote release              # Manual public release promotion
```

### Hook-Driven Automation
```bash
# Hook management
semv hook major set "./release-script.sh"   # Configure major bump hook
semv hook major                              # Show current hook
semv hook major stub                         # Generate template

# Automated execution (hooks run after successful bumps)
semv bump major                    # Executes SEMV_MAJOR_BUMP_HOOK after tagging
```

### New Command Surface Extensions

**Version Information Commands**:
```bash
semv get rust|js|python|bash [FILE]     # Extract version from package files
semv get all                             # Show all version sources
semv set rust|js|python|bash VERSION    # Update package file versions  
semv set all VERSION                     # Update all detected packages
```

**Conflict Resolution Commands**:
```bash
semv sync                                # Auto-resolve version conflicts
semv drift                               # Analyze version drift between sources
semv resolve                             # Interactive conflict resolution
```

**Promotion & Channel Management**:
```bash
semv promote beta [VERSION]              # Promote dev → beta (latest-dev)
semv promote stable [VERSION]            # Promote beta → stable (latest + snapshot)
semv promote release [VERSION]           # Promote stable → release (public)
```

**Hook Management Commands**:
```bash  
semv hook major|minor|patch|dev          # Show current hook
semv hook TYPE set "COMMAND"             # Configure hook command
semv hook TYPE stub                      # Generate hook template
semv hook TYPE remove                    # Remove hook configuration
```

**Enhanced Existing Commands**:
```bash
semv bump [--dev]                        # Enhanced with new labels + hooks
semv retag                               # Enhanced with auto-retagging logic
semv status                              # Enhanced with drift detection
```

### Phase 4A: Basic Resolution (Critical)
1. Project type detection (`detect_project_type()`)
2. Version parsing per ecosystem
3. Conflict detection and basic resolution
4. Sync tag creation

### Phase 4B: Enhanced Resolution  
1. Multi-language sync support
2. Catch-up mechanisms with safety flags
3. Environment variable integration
4. Advanced conflict scenarios

### Phase 5: Hook System
1. `.semvrc` configuration parsing
2. Hook command management
3. Hook execution integration
4. Template generation

### Phase 6: Visibility & Control
1. `semv get` command family implementation
2. `semv set` command family implementation  
3. `semv drift` analysis command
4. Enhanced `semv status` output

## Edge Cases & Considerations

### Version Format Variations
- **Rust**: `version = "1.2.3"` in `[package]`
- **Node**: `"version": "1.2.3"` in root object
- **Python**: `version = "1.2.3"` in `[project]` (pyproject.toml)
- **Bash**: `# semv-version: 1.2.3` or `# version: 1.2.3`

### Pre-release Label Handling
- **Standard**: `v1.2.3-alpha.1`, `v1.2.3-beta.2`, `v1.2.3-rc.1`
- **Dev State**: `v1.2.3-dev—build` (longer hyphen for visibility)  
- **Build Marker**: `v1.2.3-build.feature-x` (reversion point)

### Monorepo Considerations
- **Single Language**: All packages sync to same version
- **Multi-Language**: Each ecosystem maintains independent versioning
- **Workspace Detection**: Identify root vs submodule contexts

## Future Roadmap (Post-Production Enhancements)

### Phase 8: Workspace & Ecosystem Expansion
- **Monorepo/Workspace Support**: Coordinate versions across multiple projects
- **Extended Language Support**: Go modules, Maven, Gradle, Composer integration
- **Custom Version Patterns**: User-configurable semantic version formats
- **Advanced Conflict Resolution**: Interactive resolution with diff visualization

### Phase 9: Integration & Automation
- **IDE Plugins**: VS Code, IntelliJ, Vim extensions for semv commands
- **CI/CD Integration**: GitHub Actions, GitLab CI, Jenkins pipeline components  
- **Container Versioning**: Docker image tagging synchronized with semv
- **Release Automation**: Automated changelog generation and release notes

### Phase 10: Advanced Features
- **Semantic Code Analysis**: Automatic bump detection from code changes
- **Version Deprecation Management**: Lifecycle tracking for older versions
- **Cross-Repository Coordination**: Multi-repo version synchronization
- **Rollback Capabilities**: Safe version rollback with dependency checking

### Integration Opportunities Identified
- Package registry publishing (crates.io, npm, PyPI integration)
- Git hosting platform integration (GitHub releases, GitLab releases)
- Documentation site version coordination (docs.rs, GitHub Pages)
- Dependency management integration (dependabot coordination)

---

**Living Document Status**: All current requirements captured and synchronized with implementation plan