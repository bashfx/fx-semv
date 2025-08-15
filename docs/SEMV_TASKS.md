# SEMV_TASKS.md

## Phase 1: BashFX Compliance Foundation
**Goal**: Convert existing semv to proper BashFX architecture without breaking functionality

### 1.1 Version Tracking & Metadata
- [ ] Add revision tracking comment under shebang (`# semv-revision: 2.0.0`)
- [ ] Update meta comment block with proper BashFX format
- [ ] Add portable commands tracking comment

### 1.2 Color & Glyph Migration
- [ ] Replace custom color variables with `esc.sh` standards
  - `red=$(tput setaf 202)` → `readonly red=$'\x1B[38;5;197m'`
  - `green=$(tput setaf 2)` → `readonly green=$'\x1B[32m'`
  - Map all existing colors to closest esc.sh equivalents
- [ ] Replace custom glyphs with esc.sh standards
  - `pass="\xE2\x9C\x93"` → `pass=$'\u2713'`
  - `fail="${red}\xE2\x9C\x97"` → `fail=$'\u2715'`
  - Standardize all symbol usage

### 1.3 Predictable Variables Standardization
- [ ] Convert function locals to BashFX standards
  - `count_val` → `count`, `temp_result` → `res`
  - `latest` → `tag`, `new_version` → `vers`
  - `val` → `res`, `this` → `curr`
- [ ] Implement `ret=1` default pattern in all functions
- [ ] Standardize string/path variables (`str`, `msg`, `path`, `src`, `dest`)

### 1.4 Function Comment Standardization
- [ ] Add function comment bars for all major functions
- [ ] Group related helper functions under parent comments
- [ ] Document function arguments and return values

## Phase 2: Function Ordinality & Structure
**Goal**: Apply proper BashFX function hierarchy and interface patterns

### 2.1 Function Ordinality Restructuring
- [ ] **High-Order Functions** (`do_*`):
  - Rename existing commands: `do_latest_tag`, `do_next_semver`, `do_retag`, etc.
  - Add user-level guards and input validation
  - Handle user interaction and confirmation prompts
- [ ] **Mid-Level Helpers** (`_*`):
  - Create: `_validate_version`, `_parse_commits`, `_check_repo_state`
  - Break down complex logic from high-order functions
- [ ] **Low-Level Literals** (`__*`):
  - Preserve existing git operations: `__git_tag_create`, `__git_push_tags`
  - Raw system operations: `__write_build_file`, `__read_git_config`

### 2.2 Standard Interface Implementation
- [ ] **`main()` Function**:
  - Orchestrate script lifecycle
  - Call `options()` → `dispatch()` pattern
  - Handle early exits and error states
- [ ] **`dispatch()` Function**:
  - Convert existing case statement to proper dispatcher
  - Route to `do_*` functions based on commands
  - Standardize argument passing
- [ ] **`usage()` Function**:
  - Convert embedded help to proper usage function
  - Use BashFX help formatting standards
  - Make independent (no state dependencies)
- [ ] **`options()` Function**:
  - Implement standard flag parsing
  - Map existing flags to BashFX standards:
    - `-d` → `opt_debug`, `-t` → `opt_trace`
    - `-y` → `opt_yes`, `-f` → `opt_force`
    - `-D` → `opt_dev` (master dev flag)

### 2.3 Stream Usage Cleanup
- [ ] Audit all output functions for proper stream usage
- [ ] Ensure `stderr` for messages, `stdout` for capture
- [ ] Implement silenceability levels (QUIET(n))
- [ ] Add proper error/fatal distinction

## Phase 3: XDG+ Integration & Lifecycle
**Goal**: Implement proper path management and BashFX lifecycle functions

### 3.1 XDG+ Path Compliance
- [ ] Define XDG+ variables for semv
  - `SEMV_HOME="${XDG_HOME}/fx/semv"`
  - `SEMV_CONFIG="${XDG_ETC}/fx/semv/config"`
  - `SEMV_DATA="${XDG_DATA}/fx/semv"`
- [ ] Replace hardcoded paths with XDG+ variables
- [ ] Implement path creation and validation helpers

### 3.2 Configuration & RC File Management
- [ ] Create semv.rc file for session state
- [ ] Implement linking/unlinking for profile integration
- [ ] Add configuration file support for defaults
- [ ] Support user overrides and environment variables

### 3.3 BashFX Lifecycle Functions
- [ ] **`do_install()`**: Install semv to XDG+ locations
  - Copy script to `${XDG_LIB}/fx/semv/`
  - Create symlink in `${XDG_BIN}/semv`
  - Set up configuration directories
- [ ] **`do_uninstall()`**: Clean removal
  - Remove symlinks and files
  - Clean up configuration
  - Restore pre-install state
- [ ] **`do_reset()`**: Reset configuration to defaults
- [ ] **`do_status()`**: Show installation and configuration status

## Phase 4: Sync Feature Implementation
**Goal**: Add multi-language version synchronization capabilities

### 4.1 Project Detection Infrastructure
- [ ] **`_detect_project_type()`**: Auto-detect project language
  - Check for Cargo.toml, package.json, pyproject.toml
  - Check for bash script meta comments
  - Handle multiple project types in root
- [ ] **`_validate_project_structure()`**: Ensure single version source
- [ ] **`_get_project_version()`**: Extract version from detected source

### 4.2 Version Source Parsing
- [ ] **`__parse_cargo_version()`**: Extract from Cargo.toml
- [ ] **`__parse_package_version()`**: Extract from package.json
- [ ] **`__parse_pyproject_version()`**: Extract from pyproject.toml
- [ ] **`__parse_bash_version()`**: Extract from script meta comments
- [ ] **`__parse_cursor_version()`**: Extract from .build file

### 4.3 Version Source Writing
- [ ] **`__write_cargo_version()`**: Update Cargo.toml version
- [ ] **`__write_package_version()`**: Update package.json version
- [ ] **`__write_pyproject_version()`**: Update pyproject.toml version
- [ ] **`__write_bash_version()`**: Update script meta version
- [ ] **`__write_cursor_version()`**: Update .build file

### 4.4 Sync Command Implementation
- [ ] **`do_sync()`**: Main sync orchestrator
  - Gather all version sources
  - Find highest version (winner)
  - Update all other sources to match
  - Update cursor with sync state
- [ ] **`do_validate()`**: Check all sources are in sync
- [ ] **`do_drift()`**: Show version mismatches
- [ ] Add sync integration to existing `do_bump()` workflow

### 4.5 Build Cursor Enhancement
- [ ] Default .build file creation (unless `--no-cursor`)
- [ ] Support `NO_BUILD_CURSOR` environment variable
- [ ] Track sync source and state in cursor
- [ ] Integrate cursor with existing build info generation

## Phase 5: Enhanced Workflow Features
**Goal**: Add workflow automation and advanced features

### 5.1 Workflow Macros
- [ ] **`do_pre_commit()`**: Pre-commit validation hook
  - Check version sync status
  - Auto-sync if drift detected
  - Block commit if inconsistent
- [ ] **`do_release()`**: Full release workflow
  - Sync versions
  - Create tags
  - Generate release notes
- [ ] **`do_audit()`**: Full project version health check

### 5.2 Advanced Features
- [ ] Support for workspace/monorepo scenarios
- [ ] Custom version pattern matching via config
- [ ] Integration with CI/CD workflows
- [ ] Version rollback capabilities

## Phase 6: Testing & Documentation
**Goal**: Ensure reliability and maintainability

### 6.1 Testing Infrastructure
- [ ] Create test suite for core semver logic
- [ ] Test sync functionality across all supported languages
- [ ] Test edge cases and error conditions
- [ ] Performance testing and optimization

### 6.2 Documentation
- [ ] Update embedded help documentation
- [ ] Create comprehensive usage examples
- [ ] Document sync workflows and best practices
- [ ] Add troubleshooting guide

## Risk Mitigation Checkpoints

### After Phase 1:
- [ ] Verify all existing commands work identically
- [ ] Test color/glyph changes in various terminals
- [ ] Validate no performance regression

### After Phase 2:
- [ ] Comprehensive testing of refactored functions
- [ ] Verify git operations remain intact
- [ ] Test error handling and edge cases

### After Phase 3:
- [ ] Test XDG+ path creation and permissions
- [ ] Verify install/uninstall cycles
- [ ] Test configuration management

### After Phase 4:
- [ ] Test sync with real Rust/JS/Python projects
- [ ] Verify version format handling across languages
- [ ] Test conflict resolution scenarios

### After Phase 5:
- [ ] Test workflow integration scenarios
- [ ] Verify pre-commit hook functionality
- [ ] Test release automation

---

**Success Criteria**: 
- ✅ All existing functionality preserved
- ✅ Full BashFX architecture compliance  
- ✅ Multi-language sync capability
- ✅ Clean install/uninstall lifecycle
- ✅ Enhanced workflow automation