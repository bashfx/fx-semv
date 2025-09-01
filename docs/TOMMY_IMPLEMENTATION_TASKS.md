# SEMV Implementation Tasks for Tommy
*KEEPER's Documentation for Iteration 20 Work*

## ⚠️ CRITICAL: Tommy Pre-Implementation Protocol

**BEFORE STARTING - TOMMY MUST READ BASHFX v3 ARCHITECTURE**:
Tommy has no soul persistence between sessions and will have forgotten BashFX v3 patterns. 

**MANDATORY READING ORDER**:
1. `~/repos/shell/bashfx/fx-gitsim/ARCHITECTURE.md` - BashFX v3 core patterns
2. `~/repos/shell/bashfx/fx-gitsim/CONVENTIONS.md` - Function naming and organization
3. `~/repos/shell/bashfx/fx-semv/parts/` - Review existing SEMV structure (15 parts)

**KEY PATTERNS TO REMEMBER**:
- Function ordinality: `do_*` for commands, `__*` for private helpers
- Proper stderr/stdout discipline
- XDG+ compliant paths
- 0=true flag semantics
- Parts system organization

---

## Project Status
- **MVP Functions**: ✅ Complete (`do_inspect`, `do_auto` implemented)
- **Missing Critical**: `do_can_semver()` function (spec in MISSING_FUNCTION_SPEC.md)
- **Enhancement Ready**: View system + Boxy integration

---

## Task 1: Implement Missing Function (1 SP)
**File**: `parts/13_commands.sh`
**Location**: After line 677 (after `do_auto()`)
**Spec**: See `MISSING_FUNCTION_SPEC.md`

---

## Task 2: View System Implementation (2 SP)
**Objective**: Add `--view=data/simple/full` support

### Option Parsing Enhancement
**File**: `parts/02_options.sh` (likely location)
**Add**:
```bash
--view=*)
    opt_view="${arg#*=}"
    shift
    ;;
```

### View Mode Functions
**File**: `parts/03_printers.sh`
**Add after existing boxy functions**:
```bash
# View mode detection
get_view_mode() {
    case "${opt_view:-full}" in
        data) echo "data" ;;
        simple) echo "simple" ;;
        *) echo "full" ;;
    esac
}

# Enhanced printer with view support
__print_enhanced() {
    local level="$1"
    local msg="$2" 
    local use_boxy="${3:-0}"  # Explicit boxy control
    
    local view_mode=$(get_view_mode)
    
    # Data view: plain text only
    if [[ "$view_mode" == "data" ]]; then
        echo "$msg" >&2
        return 0
    fi
    
    # Simple view: basic formatting, no boxy
    if [[ "$view_mode" == "simple" ]]; then
        case "$level" in
            info) info "$msg" ;;
            okay) okay "$msg" ;;
            warn) warn "$msg" ;;
            error) error "$msg" ;;
        esac
        return 0
    fi
    
    # Full view: boxy only when explicitly requested
    if [[ "$SEMV_USE_BOXY" == "1" ]] && [[ "$use_boxy" == "1" ]] && command_exists boxy; then
        boxy_msg "$level" "$msg"
    else
        case "$level" in
            info) info "$msg" ;;
            okay) okay "$msg" ;;
            warn) warn "$msg" ;;
            error) error "$msg" ;;
        esac
    fi
}
```

---

## Task 3: Boxy Integration for End States (2 SP)
**Objective**: Apply TaskDB boxy wisdom to SEMV end states only

### Key Principle from TaskDB Experience
**Boxy is for results, not progress**:
- ✅ `semv status` final output
- ✅ `semv audit` summary
- ✅ Version drift warnings
- ❌ Individual progress messages

### Functions to Enhance
**Target end-state functions**:
1. `do_status()` - Use boxy for final status display
2. `do_audit()` - Use boxy for comprehensive report
3. `do_drift()` - Use boxy for drift summary
4. `do_get_all()` - Use boxy for version overview

**Implementation Pattern**:
```bash
# In target functions, for final output only
if [[ "$SEMV_USE_BOXY" == "1" ]] && command_exists boxy; then
    {
        echo "Status Summary"
        echo "=============="
        echo "Repository: $(basename "$PWD")"
        echo "Latest: $version"
        echo "Build: $build_count"
    } | boxy --theme info --title "📊 SEMV Status"
else
    info "Repository: $(basename "$PWD")"
    info "Latest: $version"
    info "Build: $build_count"
fi
```

---

## Task 4: Trace Message Audit (1 SP)
**Objective**: Fix misused trace messages

### Files to Modify
**parts/08_detect.sh**:
- Lines 33, 41, 49, 54, 65, 75: Change `trace` → `info`
- Keep line 82 as `trace` (internal summary)

**parts/13_commands.sh**:
- Line 45: Change `trace "Bump: $latest -> $new_version"` → `status "Bump: $latest -> $new_version"`
- Line 657: Keep as `trace` (internal mode tracking)

### Default Trace Behavior
**File**: `parts/03_printers.sh`
**Current**: `if [[ "$opt_trace" -eq 0 ]]`
**Change to**: `if [[ "$opt_trace" -eq 0 ]] || [[ "$opt_debug" -eq 0 ]]`

---

## Task 5: Testing Integration (1 SP)
**Commands to Test**:
```bash
# Basic functionality
./semv.sh can
./semv.sh status
./semv.sh audit

# View modes
./semv.sh status --view=data
./semv.sh status --view=simple
./semv.sh status --view=full

# Boxy integration
SEMV_USE_BOXY=1 ./semv.sh status
SEMV_USE_BOXY=1 ./semv.sh audit
```

---

## Implementation Order
1. **Critical**: Implement `do_can_semver()` (1 SP)
2. **Enhancement**: View system (2 SP)
3. **Visual**: Boxy end states (2 SP) 
4. **Polish**: Trace message fixes (1 SP)
5. **Validation**: Testing (1 SP)

**Total**: 7 Story Points

---

## Environment Variables
```bash
SEMV_USE_BOXY=1        # Enable boxy output
opt_view="data"        # View mode: data/simple/full
opt_trace=1            # Default OFF (use -t to enable)
```

---

## Success Criteria
- ✅ No missing function errors
- ✅ Clean output in data mode
- ✅ Boxy enhancement for end states only
- ✅ Trace messages require explicit flag
- ✅ All view modes working

---

*KEEPER's Specification - Ready for Tommy's Implementation*
*Applying TaskDB Boxy Mastery to SEMV Final Polish*