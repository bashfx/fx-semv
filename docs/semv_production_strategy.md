# SEMV Production Strategy & Requirements
**Version**: 2.0.0  
**Date**: 2025-08-26  
**Status**: Strategy Planning  

## Executive Summary

SEMV currently operates in a "commit-message-only bubble" without consulting actual project version sources, creating version drift and incorrect assumptions. The production-ready version must implement intelligent version resolution that reconciles multiple sources of truth while maintaining backward compatibility with existing command surface.

## Stakeholder Needs

### Primary Requirements
- **Version Source Resolution**: Intelligent detection and reconciliation of version conflicts
- **Project Structure Validation**: Error on ambiguous multi-language projects  
- **Synchronization Logic**: Auto-align semv with authoritative package versions
- **Semantic Version Compatibility**: Support alpha/beta/rc labels across language ecosystems
- **Backward Compatibility**: Preserve existing command surface for tool integrations

### Secondary Requirements
- **Enhanced Commit Labels**: Better mental model alignment (feat ≈ minor, not major)
- **Build System Modernization**: BashFX 2.0 compliance with build.map pattern
- **Testing Foundation**: Gitsim-based virtualized testing with visual UX
- **XDG+ Path Compliance**: Correct library paths (not ~/.local/share)

## Current State Analysis

### Architecture Status
- ✅ **Phases 1-3**: Substantial BashFX compliance progress (16 modules)
- ❌ **Version Resolution**: Missing project file detection/parsing
- ❌ **Build System**: Using older build.sh pattern without build.map
- ❌ **Testing**: Chaotic/non-functional test coverage
- ❌ **Documentation**: Incomplete specification of version resolution logic

### Technical Debt
- Path migration from XDG_SHARE to XDG+ library patterns
- Function ordinality compliance review needed
- Legacy Jules implementation uncertainty

## Version Resolution Strategy

### Source Detection Hierarchy
1. **Single Language Validation**: Error if multiple top-level package managers detected
   - Rust: `Cargo.toml [package] version`
   - Node: `package.json "version"`  
   - Python: `pyproject.toml` or `setup.py`
   - Bash: Meta-comment `# semv-version: x.x.x`

### Synchronization Logic
```bash
IF semv_local_version << package_version:
    # semv is majorly behind
    WARN "Version drift detected" (skip with --auto)
    CREATE sync_tag(package_version)  # Immediate resolution tag
    SET counting_baseline = sync_tag
    
    # Optional catch-up (user approval required)
    IF minor_catchup_requested AND !SEMV_MINOR_AUTO_SAFE:
        PROMPT "Catch up minor versions on top of sync?"
    IF major_catchup_requested AND !SEMV_MAJOR_AUTO_SAFE:
        ERROR "Major catch-up requires discrete command or consolidation"
        
ELIF package_version < git_highest_tag:
    # package is stale
    PROMPT "Update package file to match tag?" OR --auto
    
ELIF git_highest_tag < package_version < semv_calculated:
    # semv ahead via commit counting - defer to authority
    WARN "Semv counting beyond authoritative source"  
    FALLBACK to package_version
    CREATE sync_tag(package_version)
    
ELSE:
    # versions aligned
    PROCEED with normal semv logic
```

### Multi-Language Version Sync
- **Embedded Packages**: Auto-sync versions across Rust + JS + Python + Bash
- **Submodules**: Independent versioning (parent may want different child versions)
- **Detection**: Error only on version conflicts, not mere presence

### Environment Safety Flags
```bash
SEMV_MINOR_AUTO_SAFE=1    # Disable minor auto-catchup
SEMV_MAJOR_AUTO_SAFE=1    # Disable major auto-catchup  
SEMV_PATCH_AUTO_SAFE=1    # Disable patch auto-catchup
SEMV_ALL_AUTO_SAFE=1      # Disable all auto-catchup
```

### Version Label Compatibility
- **Standard Labels**: `alpha`, `beta`, `rc` support across ecosystems  
- **Dev Labels**: `-dev_build` (longer hyphen for visibility when broken)
- **Build Numbers**: Independent counter starting from 1000, never resets
- **Special Tags**: `build:note` markers for historical reversion points (non-versioning)

### Build System Integration
- **Build Counter**: Raw incremental commit count from git log
- **Build Tags**: Historical markers via `build:note` labels  
- **Build Hooks**: Per-project automation via `.semvrc` or git hooks

## Enhanced Commit Label System

### Finalized Label Mappings (Breaking Change - No Backward Compatibility)
| Label Group | Aliases | Bump Type | Behavior |
|-------------|---------|-----------|----------|
| **Major** | `major:`, `breaking:`, `api:` | Major | Ceremonious prompt + auto-cleanup |
| **Minor** | `feat:`, `feature:`, `add:`, `minor:` | Minor | Auto-tag enabled |
| **Patch** | `fix:`, `patch:`, `bug:`, `hotfix:`, `up:` | Patch | Manual only (no auto-tag) |
| **Dev** | `dev:` | Special | Broken state marker |

### Patch Version Management
- **Auto-tag**: Disabled for patch (manual `semv bump patch` required)
- **Cleanup**: Nuke old patch tags after minor/major bump (keep last 3)
- **Special Tags**: Preserve `rc`, `alpha`, `beta`, `dev`, `build` tags
- **Retag Support**: Honor existing retag functionality

### Major Bump Ceremony
```bash
# Ceremonious major bump prompt (silenced by --auto)
🎉 MAJOR BUMP DETECTED! 🎉
⚠️  You're about to introduce BREAKING CHANGES
🏗️  Auto-cleanup will remove old patch tags
🚀 Ready for the responsibility? [y/N]
```

## Testing Strategy

### Gitsim-Based Test Matrix
```bash
# Test scenarios per language ecosystem
test_rust_cargo_sync()
test_node_package_sync()  
test_python_pyproject_sync()
test_bash_metacomment_sync()

# Conflict resolution scenarios
test_version_drift_detection()
test_multi_language_error()
test_stale_package_recovery()
```

### Visual UX Requirements
- **Ceremonious Banners**: Clear test section delineation
- **Progress Indicators**: Test N of M with status symbols
- **Color Coding**: Pass/fail/warn with BashFX esc.sh standards
- **Summary Report**: Final status with failure details

## Updated Implementation Roadmap

### Phase 4A: Version Resolution Core (Priority 1 - Bash First)
**Target**: Basic resolution with Bash meta-comment support
- [ ] **Parts to Modify**: `semv-guards.sh`, `semv-git-ops.sh`, `semv-version.sh`
  - Add `is_bash_versioned()`, `get_bash_version()`, `set_bash_version()`
  - Enhance `_latest_tag()` to consider package versions
  - Add conflict detection logic

- [ ] **New Parts Needed**:
  - `semv-detect.sh` - Project type detection and validation
  - `semv-resolve.sh` - Version resolution algorithms and sync tagging
  - `semv-getset.sh` - `semv get/set` command implementations

- [ ] **Parts to Update**: `semv-dispatch.sh`, `semv-commands.sh`
  - Add new command routing: `get`, `set`, `sync`, `drift`
  - Update existing commands to use resolution logic

### Phase 4B: Multi-Language Support (Priority 2)  
**Target**: Rust, JS, Python ecosystem support
- [ ] **Extend**: `semv-detect.sh`, `semv-resolve.sh`, `semv-getset.sh`
  - Add Cargo.toml, package.json, pyproject.toml parsers
  - Implement multi-language conflict detection
  - Add environment safety flag support

### Phase 5A: Enhanced Commit Labels (Priority 3)
**Target**: New label system with ceremony  
- [ ] **Parts to Modify**: `semv-semver.sh`, `semv-commands.sh`
  - Update label parsing: `major:`, `feat:`, `fix:`, `up:`, `dev:`
  - Add major bump ceremony with cleanup logic
  - Implement patch tag nuking after minor/major bumps

### Phase 5B: Hook System (Priority 4)
**Target**: Per-project automation hooks
- [ ] **New Parts**:
  - `semv-config.sh` extension for `.semvrc` parsing  
  - `semv-hooks.sh` - Hook management and execution
- [ ] **Commands**: `semv hook` command family

### Phase 6: Build System Modernization (Priority 5)
**Target**: BashFX 2.0 compliance and testing
- [ ] Create proper `build.map` file
- [ ] Implement gitsim-based test suite
- [ ] Fix XDG+ path compliance (remove ~/.local/share usage)
- [ ] Function ordinality review and fixes

## Success Criteria (Extracted from Legacy Analysis)

### Functional Requirements
- **100% Backward Compatibility**: All existing semv 1.x commands work identically
- **Multi-Language Support**: Rust, JavaScript, Python, Bash sync functions correctly
- **BashFX Compliance**: Passes all architecture and coding standard requirements
- **Zero Data Loss**: No git history corruption during any operations

### Quality Requirements  
- **Test Coverage**: >90% code coverage with integration tests
- **Performance**: Sub-second response for common operations (info, status, next)
- **Error Handling**: Graceful failure with recovery suggestions for all edge cases
- **CI/CD Reliability**: Works consistently in automated environments

### User Experience Requirements
- **Intuitive Commands**: New users can accomplish basic tasks without documentation
- **Clear Visual Feedback**: Status indicators and progress for all operations
- **Complete Documentation**: Usage examples, troubleshooting, migration guides

## New Feature Requirements

### Project Hook System
```bash
# Per-project hooks via .semvrc or git integration
SEMV_MINOR_BUMP_HOOK="./scripts/minor_release.sh"
SEMV_MAJOR_BUMP_HOOK="./scripts/major_release.sh"  
SEMV_PATCH_BUMP_HOOK="./scripts/patch_release.sh"

# Hook management commands
semv hook major                    # Show current major hook
semv hook major "./my/script.sh"  # Set major hook
semv hook major --stub             # Generate hook template
```

### Enhanced Version Visibility
```bash
# Multi-source version inspection
semv get bash ./my-script.sh     # Get version from bash file
semv get rust                     # Get version from Cargo.toml
semv get js                       # Get version from package.json  
semv get python                   # Get version from pyproject.toml
semv get all                      # List ALL version sources

# Version synchronization  
semv set rust 1.2.3              # Update Cargo.toml version
semv set js 1.2.3                 # Update package.json version
semv set all 1.2.3                # Update all package files
```

### Project Configuration
- **`.semvrc`**: Per-project settings, hook definitions, tracked files
- **Multi-file Tracking**: Specify which bash files to track for version
- **Automation Integration**: Publishing to crates.io, npm, PyPI, GitHub releases

## Open Questions for Refinement

### Commit Label Strategy
1. Should `feat:` remain major bump for backward compatibility, or migrate to minor?
2. What aliases should be supported? (`feature:`, `add:`, `new:`?)
3. How to handle mixed label usage in commit history?

### Semantic Version Labels  
4. How should `-dev_N` interact with standard `-alpha.N` patterns?
5. Should build counter reset on version bumps or persist independently?
6. Which ecosystems support custom suffixes vs standard labels?

### Testing Scope
7. Should tests cover all language combinations or focus on single-ecosystem scenarios?
8. What level of git history complexity should be tested (merges, rebases, etc.)?

### Implementation Priority
9. Should version resolution be implemented for all languages simultaneously or iteratively?
10. Is there a preferred language ecosystem to validate the approach first?

---

**Next Steps**: Refine open questions → Create detailed technical specification → Begin Phase 4 implementation