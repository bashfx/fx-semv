# SEMV Consolidated Roadmap & Task Tracker

## Project Status Summary
- **Completion**: 95% feature complete
- **Architecture**: BashFX v3 compliant ✅
- **Production Ready**: After completing 3 missing functions (1-2 hours)

---

## IMMEDIATE PRIORITIES (MVP Completion)

### 🔴 Critical: Missing Functions (4 story points total)
**Timeline: 1-2 hours** | **Blocks: Production Release**

#### Implementation Tasks:
1. **`do_inspect()`** - Display dispatch table (1 SP)
   ```bash
   do_inspect() {
       info "SEMV Dispatch Table:";
       func ls "$SEMV_PATH" | grep "^do_" | sort;
       return 0;
   }
   ```

2. **`do_auto()`** - Auto mode for tool integration (2 SP)
   ```bash
   do_auto() {
       local action="${1:-sync}";
       case "$action" in
           sync) do_sync "$@" ;;
           validate) do_validate "$@" ;;
           *) do_sync "$@" ;;
       esac
   }
   ```

3. **Remove `do_snip`** - Deprecated, remove from dispatch (1 SP)

**Deliverable**: Fully functional semv with no "not implemented" errors

---

## SHORT TERM ENHANCEMENTS

### 🟡 High Priority: Version Source Transparency (13 story points)
**Timeline: 2-3 sprints** | **Issue: Users can't see which file provided version**

#### Phase Breakdown:
1. **Core Infrastructure** (3 SP)
   - Modify `__get_single_package_version()` to return file paths
   - Update `_get_package_version()` for new format
   - Target: `parts/09_resolve.sh`

2. **Detection Transparency** (2 SP)
   - Enhanced logging in `detect_bash_version_file()`
   - Trace messages during scanning
   - Target: `parts/10_getset.sh`, `parts/08_detect.sh`

3. **Output Standardization** (3 SP)
   - Format: `type (file_path): version`
   - Example: `bash (./semv.sh): 2.0.0`
   - Target: `parts/10_getset.sh`

4. **Python Disambiguation** (1 SP)
   - Show exact file: pyproject.toml OR setup.py
   
5. **Verbose Mode** (2 SP)
   - Add `-v` flag for detailed detection

6. **Testing** (2 SP)
   - Multiple .sh file scenarios
   - Edge cases

### 🟡 High Priority: Code Hygiene (4 story points)
**Timeline: 2-3 hours**

- [ ] Remove stale SEMV_HOME migration comments (1 SP)
- [ ] Shellcheck pass and fixes (3 SP)

---

## MEDIUM TERM ENHANCEMENTS

### 🟢 Boxy Integration & View System (10 story points)
**Timeline: 3-4 hours** | **Enhances: User Experience**

#### Implementation Strategy:
1. **View System** (2 SP)
   - Add `--view=data` for plain output (no decorations)
   - Add `--view=simple` for basic formatting (no boxy)
   - Default `--view=full` with optional boxy
   
2. **Trace Message Fixes** (1 SP)
   - Change detection messages from trace → info
   - Default `TRACE_MODE=0` (opt-in with `-t` or `-D`)
   
3. **Wrapper Functions** (2 SP)
   ```bash
   # In 03_printers.sh
   boxy_status() {
       if [[ "$SEMV_USE_BOXY" == "1" ]] && command_exists boxy; then
           echo "$1" | boxy --theme "$2" "${@:3}";
       else
           case "$2" in
               success) okay "$1" ;;
               error) error "$1" ;;
               *) info "$1" ;;
           esac
       fi
   }
   ```

4. **Themed Output Integration** (2 SP)
   - Error messages with `--theme error`
   - Success feedback with `--theme success`
   - Status boxes for visual reports

5. **Dashboard Views** (2 SP)
   - Build count visualization
   - Sync status display
   - Version drift indicators

**Enable via**: `SEMV_USE_BOXY=1` environment variable

---

## COMPLETED MILESTONES ✅

### Recently Completed (M1-M14)
- ✅ Config path consolidation (SEMV_ETC)
- ✅ Test alignment with BashFX KB pattern
- ✅ Command surface completion (audit, pre-commit, etc.)
- ✅ Remote operations (latest_remote, remote_compare)
- ✅ Promotion workflows (beta, stable, release)
- ✅ Multi-language sync support
- ✅ Label scheme v2.0 (major/minor/patch/dev patterns)
- ✅ Baseline guards and drift analysis
- ✅ Pre-commit auto-staging option

---

## TASK PRIORITY MATRIX

| Priority | Task | Story Points | Timeline | Status |
|----------|------|--------------|----------|--------|
| ✅ P0 | Missing Functions | 4 | COMPLETED | ✅ DONE |
| ✅ P1 | Version Transparency | 3* | COMPLETED | ✅ DONE |
| ✅ P1 | Code Hygiene | 4 | COMPLETED | ✅ DONE |
| ✅ P2 | View System & Boxy | 10 | COMPLETED | ✅ DONE |
| 🟢 P2 | Documentation Update | 3 | 2 hours | TODO |

**Total Completed**: 21 story points ✅
**Outstanding**: 3 story points
*Strategic 3 SP solution vs original 13 SP estimate

### Backlog for Consideration
- **stderr→stdout switching in data mode** - Complex, may not be needed
- **Enhanced automation support** - Will be addressed in Rust rewrite

---

## Implementation Checklist

### Week 1 (MVP Release)
- [ ] Implement 3 missing functions
- [ ] Test build process
- [ ] Validate all command surface functions
- [ ] Tag v2.0.0 release

### Week 2 (Polish)
- [ ] Code hygiene pass
- [ ] Begin version transparency Phase 1
- [ ] Update documentation

### Week 3+ (Enhancements)
- [ ] Complete version transparency
- [ ] Integrate boxy for enhanced UX
- [ ] Performance optimization

---

## Technical Notes

### File Organization
- **Parts System**: 15 well-organized parts via build.sh
- **Key Files**:
  - `parts/10_getset.sh` - Version get/set operations
  - `parts/09_resolve.sh` - Conflict resolution
  - `parts/08_detect.sh` - Project detection
  - `parts/03_printers.sh` - Output functions (boxy target)

### Testing Commands
```bash
# Build the project
./build.sh

# Test missing functions
./semv.sh inspect
./semv.sh auto

# Test version detection
./semv.sh get all

# Test with verbose (after implementation)
./semv.sh get all -v
```

### Environment Variables
- `SEMV_ETC` - Configuration directory
- `SEMV_USE_BOXY` - Enable boxy integration (future)
- `SEMV_SAFE_CONFIRM` - Safe confirmation mode
- `SEMV_FEATURE_HYBRID` - Hybrid dispatch mapping

---

## Success Metrics
- ✅ No "not implemented" errors
- ✅ Clear version source reporting
- ✅ Clean shellcheck output
- ✅ Optional visual enhancements via boxy
- ✅ Comprehensive test coverage

---

*Last Updated: 2025-09-01*
*Tracking: 32 outstanding story points across 4 priority areas*