# TODO.md - SEMV Production Tasks

## Critical Implementation Gap Resolution

### Replace Legacy Placeholder Functions
**Issue Found**: Existing parts contain placeholder implementations marked "Future Implementation"

- [ ] **Replace `do_sync()` placeholder** in `parts/semv_commands.sh` with actual implementation from `09_resolve.sh`
- [ ] **Replace `do_validate()` placeholder** with version drift analysis functionality  
- [ ] **Replace `do_drift()` placeholder** with conflict detection and reporting
- [ ] **Verify function_exists() checks** in dispatch don't fail for new implementations
- [ ] **Integration test**: Ensure new modules properly replace legacy placeholders

### Legacy Function Migration
- [ ] **Extract working functions** from existing parts before replacement
- [ ] **Preserve existing command surface** that works correctly
- [ ] **Validate I/O compatibility** between old and new implementations
- [ ] **Test backward compatibility** with existing tool integrations

## Success Criteria Integration (From Legacy Analysis)

### Performance Validation Required
- [ ] **Sub-second response time** for common operations (info, status, next)
- [ ] **Large repository testing** (1000+ tags, deep history)
- [ ] **Memory usage profiling** for complex git operations
- [ ] **CI/CD environment testing** across different platforms

### Quality Checkpoints Added
- [ ] **>90% test coverage** with integration tests using gitsim
- [ ] **Zero data loss validation** - no git history corruption
- [ ] **Error handling completeness** - graceful failure for all edge cases
- [ ] **Documentation completeness** - usage examples and troubleshooting

### User Experience Validation  
- [ ] **New user testing** - basic tasks without documentation
- [ ] **Visual feedback consistency** - status indicators and progress
- [ ] **Migration path testing** - upgrade from legacy semv smoothly

### Fix Shebang Rule Violations
**Only 01_config.sh should have shebang - remove from all other parts:**
- [ ] Remove shebang from `02_colors.sh` through `15_dispatch.sh`
- [ ] Verify `01_config.sh` has correct shebang: `#!/usr/bin/env bash`

## Missing Implementation Files

### Create Missing Part Files
- [ ] `01_config.sh` - Rename existing `semv_config.sh`, remove shebang from others
- [ ] `02_colors.sh` - Rename existing `semv_colors.sh`, remove shebang  
- [ ] `03_printers.sh` - Rename existing `semv_printers.sh`, remove shebang
- [ ] `04_options.sh` - Rename existing `semv_options.sh`, remove shebang
- [ ] `05_guards.sh` - Rename existing `semv_guards.sh`, remove shebang
- [ ] `06_git-ops.sh` - Rename existing `semv_git-ops.sh`, remove shebang
- [ ] `07_version.sh` - Rename existing `semv_version.sh`, remove shebang
- [ ] `08_detect.sh` - ✅ Created (new version resolution)
- [ ] `09_resolve.sh` - ✅ Created (conflict handling)
- [ ] `10_getset.sh` - ✅ Created (get/set commands)
- [ ] `11_semver.sh` - Rename existing `semv_semver.sh`, remove shebang
- [ ] `12_lifecycle.sh` - Rename existing `semv_lifecycle.sh`, remove shebang
- [ ] `13_commands.sh` - Rename existing `semv_commands.sh`, remove shebang
- [ ] `14_hooks.sh` - ✅ Created (tag retagging + hooks)
- [ ] `15_dispatch.sh` - Rename existing `semv_dispatch.sh`, remove shebang

## Enhanced Commit Labels Implementation

### Update Label Parsing (Breaking Change - No Backward Compatibility)
- [ ] Update `11_semver.sh` label constants:
  ```bash
  # Old labels
  SEMV_MAJ_LABEL="brk"      # ❌ Remove
  SEMV_FEAT_LABEL="feat"    # ❌ Change behavior
  
  # New label mappings  
  MAJOR_LABELS=("major:" "breaking:" "api:")      # Major bumps
  MINOR_LABELS=("feat:" "feature:" "add:" "minor:") # Minor bumps  
  PATCH_LABELS=("fix:" "patch:" "bug:" "hotfix:" "up:") # Patch bumps
  DEV_LABELS=("dev:")                             # Special dev marker
  ```

### Patch Tag Management  
- [ ] Update `do_bump` to NOT auto-tag patch versions (manual only)
- [ ] Add patch tag cleanup after minor/major bumps (keep last 3)
- [ ] Preserve special tags (rc, alpha, beta, dev, build) during cleanup

### Major Bump Ceremony
- [ ] Add ceremonious prompts for major bumps:
  ```bash
  echo "🎉 MAJOR BUMP DETECTED! 🎉"  
  echo "⚠️  You're about to introduce BREAKING CHANGES"
  echo "🏗️  Auto-cleanup will remove old patch tags"
  echo "🚀 Ready for the responsibility? [y/N]"
  ```
- [ ] Silence ceremony with `--auto` flag

## Version Resolution System

### Phase 4A: Basic Bash Resolution  
- [ ] Test `08_detect.sh` project detection for bash files
- [ ] Test `09_resolve.sh` conflict detection and sync tagging
- [ ] Test `10_getset.sh` bash version get/set operations
- [ ] Integration testing: detect → resolve → sync workflow

### Phase 4B: Multi-Language Support
- [ ] Extend detection for Rust (Cargo.toml)
- [ ] Extend detection for JavaScript (package.json)
- [ ] Extend detection for Python (pyproject.toml/setup.py)
- [ ] Test multi-language conflict scenarios
- [ ] Implement environment safety flags (`SEMV_*_AUTO_SAFE`)

## Tag Retagging System  

### Auto-Retagging Logic
- [ ] Test `__retag_dev()` for development versions
- [ ] Test `__retag_beta()` for beta promotions  
- [ ] Test `__retag_stable()` for stable releases
- [ ] Test stable snapshot creation (`v1.2.3-stable`)

### Promotion System
- [ ] Test `do_promote_to_beta()` dev → beta promotion
- [ ] Test `do_promote_to_stable()` beta → stable promotion  
- [ ] Test `do_promote_to_release()` stable → public release
- [ ] Test promotion ceremony and confirmations

### Hook System
- [ ] Test hook configuration via `.semvrc`
- [ ] Test hook stub generation
- [ ] Test hook execution with version arguments
- [ ] Test hook management commands (`semv hook major set`)

## Command Surface Updates

### New Commands to Add to Dispatch
- [ ] `get` - Version information retrieval
- [ ] `set` - Version updating across package files
- [ ] `sync` - Conflict resolution and alignment
- [ ] `drift` - Version drift analysis  
- [ ] `promote` - Channel promotion (dev → beta → stable → release)
- [ ] `hook` - Hook management commands

### Enhanced Existing Commands
- [ ] Update `bump` to use new label system
- [ ] Update `bump` to execute hooks after tagging
- [ ] Update `retag` to use new retagging logic
- [ ] Add tag cleanup to `bump` operations

## Testing Infrastructure

### Gitsim-Based Test Suite
- [ ] Create test runner with BashFX visual standards
- [ ] Test scenarios for each language ecosystem
- [ ] Test conflict resolution edge cases  
- [ ] Test tag retagging workflows
- [ ] Test hook execution and management

### Visual Test UX Requirements  
- [ ] Ceremonious test banners with clear section delineation
- [ ] Progress indicators: "Test N of M" with status symbols
- [ ] Color coding: pass/fail/warn with esc.sh standards
- [ ] Final summary report with failure details

## XDG+ Path Compliance

### Path Migration
- [ ] Verify no usage of `~/.local/share` (should use XDG_LIB)
- [ ] Update all path references to use XDG+ variables
- [ ] Test path creation and permissions

## Function Ordinality Review

### BashFX Compliance Check
- [ ] Review all functions for proper `do_*`, `_*`, `__*` hierarchy
- [ ] Ensure stream usage compliance (stderr for messages, stdout for capture)  
- [ ] Validate predictable variable naming (`ret`, `res`, `path`, `curr`)

## Integration and Final Testing

### Build System Validation
- [ ] Test `build.sh` with new `build.map` 
- [ ] Verify all 15 parts assemble correctly
- [ ] Test generated `semv.sh` functionality
- [ ] Validate no duplicate shebangs in assembled output

### Backward Compatibility Testing
- [ ] Test all existing command surface preserved
- [ ] Validate existing tool integrations still work
- [ ] Test version calculation logic against legacy semv
- [ ] Verify git repository operations

### Performance and Edge Cases  
- [ ] Test with large git repositories
- [ ] Test with complex version histories
- [ ] Test error handling and recovery
- [ ] Memory usage and execution time validation

## Documentation Updates

### User Documentation
- [ ] Update README.md with new command surface
- [ ] Document new commit label system (breaking change notice)
- [ ] Add promotion workflow examples
- [ ] Update troubleshooting guide

### Developer Documentation  
- [ ] Document hook system architecture
- [ ] Add version resolution algorithm explanation  
- [ ] Create contribution guide for new language support
- [ ] Add testing methodology documentation

---

**Priority Order**: 
1. Build system fixes (Critical - blocks everything)
2. File renaming and shebang fixes (Critical - required for assembly)
3. Enhanced commit labels (High - core functionality)  
4. Version resolution Phase 4A (High - major feature)
5. Tag retagging system (Medium - workflow improvement)
6. Testing infrastructure (Medium - validation)
7. Documentation (Low - polish)

**Estimated Total Effort**: 2-3 development sessions for core functionality + 1 session for testing/polish