# SEMV Visual Language & View System Specification

## Executive Summary
This specification defines the visual output system for SEMV, including:
- View modes for different use cases (data, simple, full)
- Proper stderr/stdout routing based on context
- Trace message visibility controls
- Boxy integration for enhanced visual feedback
- Consistent visual language across all outputs

---

## View System Architecture

### View Modes

#### 1. `--view=data` (Machine-Readable Mode)
**Purpose:** Clean data output for piping and automation
```bash
# Characteristics:
- NO decorations (no colors, icons, boxes)
- NO boxy output regardless of SEMV_USE_BOXY
- Only essential data output
- Silent trace messages (TRACE_MODE=0 enforced)
- Standard stderr/stdout behavior maintained

# Example:
$ semv get all --view=data
rust:2.0.0:./Cargo.toml
javascript:2.0.0:./package.json
bash:2.0.0:./semv.sh

$ semv status --view=data | jq -R 'split(":") | {type: .[0], version: .[1], file: .[2]}'
```

#### 2. `--view=simple` (Minimal Visual Mode)
**Purpose:** Human-readable without visual enhancements
```bash
# Characteristics:
- Basic colors and formatting
- NO boxy output (even if SEMV_USE_BOXY=1)
- Standard stderr for messages
- Trace hidden by default (requires -t flag)

# Example:
$ semv status --view=simple
Repository: fx-semv
Latest tag: v2.0.0
Build count: 42
```

#### 3. `--view=full` (Default - Rich Visual Mode)
**Purpose:** Full visual experience with optional boxy
```bash
# Characteristics:
- Full colors and icons
- Boxy output if SEMV_USE_BOXY=1
- Standard stderr for messages
- Trace hidden by default (requires -t flag)

# Example with boxy:
$ SEMV_USE_BOXY=1 semv status
╔══════════════════════════════╗
║      SEMV Status Report      ║
╠══════════════════════════════╣
║ Repository: fx-semv          ║
║ Latest tag: v2.0.0           ║
║ Build count: 42              ║
╚══════════════════════════════╝
```

---

## Message Level Hierarchy

### QUIET(1) - User-Facing Messages (Default ON)
These print to stderr by default, visible unless `--quiet`

| Level | Function | Icon | Color | Use Case | Stream |
|-------|----------|------|-------|----------|--------|
| fatal | `fatal()` | ☠️ | red | Unrecoverable errors, exits | stderr |
| error | `error()` | ❌ | red | Recoverable errors | stderr |
| warn | `warn()` | ⚠️ | yellow | Important warnings | stderr |
| info | `info()` | ℹ️ | cyan | General information | stderr |
| okay | `okay()` | ✓ | green | Success confirmations | stderr |
| status | `status()` | 📊 | blue | State reporting | stderr |

**Note:** All messages maintain standard stderr output. Data view simply removes decorations.

### QUIET(2) - Debug Messages (Default OFF)
These require explicit flags to display

| Level | Function | Icon | Color | Flag Required | Use Case |
|-------|----------|------|-------|---------------|----------|
| trace | `trace()` | ··· | grey | `-t` or `-D` | Internal calculations |
| debug | `debug()` | 🐛 | magenta | `-D` | Developer diagnostics |
| silly | `silly()` | 🤪 | dim | `-DD` | Excessive detail |

---

## Trace Message Audit & Fixes

### Problem: Trace Messages Used as Final Output
Current trace messages that should be info/status:

```bash
# WRONG - User-facing detection results as trace
trace "Detected Rust project (Cargo.toml with [package])";

# RIGHT - Should be info or status
info "Detected Rust project (Cargo.toml with [package])";
```

### Required Changes:

1. **Project Detection** (`parts/08_detect.sh`)
   - Lines 33, 41, 49, 54, 65, 75: Change to `info`
   - Line 82: Keep as trace (summary for debugging)

2. **Version Resolution** (`parts/09_resolve.sh`)
   - Lines 44-46: Keep as trace (interim calculations)
   - Line 259: Keep as trace (internal strategy)

3. **Command Execution** (`parts/13_commands.sh`)
   - Line 45: Change to `status` (user needs to see bump)
   - Line 657: Keep as trace (internal mode tracking)

---

## Boxy Integration Pattern

### Implementation in `03_printers.sh`

```bash
# View mode detection
get_view_mode() {
    case "${opt_view:-full}" in
        data) echo "data" ;;
        simple) echo "simple" ;;
        *) echo "full" ;;
    esac
}

# Simplified - no stream switching needed
# All output stays on stderr, data view just removes decorations

# Enhanced printer with view support
__print_message() {
    local level="$1"
    local msg="$2"
    local color="$3"
    local icon="$4"
    local use_boxy="${5:-0}"  # Explicit boxy flag (default: no)
    
    local view_mode=$(get_view_mode)
    
    # Data view: plain text, no decorations
    if [[ "$view_mode" == "data" ]]; then
        echo "$msg" >&2
        return 0
    fi
    
    # Simple view: basic formatting, no boxy
    if [[ "$view_mode" == "simple" ]]; then
        __printf "${icon} ${msg}\n" "$color" >&2
        return 0
    fi
    
    # Full view: boxy only for end states/results when explicitly requested
    if [[ "$SEMV_USE_BOXY" == "1" ]] && [[ "$use_boxy" == "1" ]] && command_exists boxy; then
        echo "$msg" | boxy --theme "$level" --title "$icon $level" >&2
    else
        __printf "${icon} ${msg}\n" "$color" >&2
    fi
}

# Special function for final results/status (uses boxy when appropriate)
print_result() {
    local level="$1"
    local msg="$2"
    local color="$3"
    local icon="$4"
    
    # Results/end states can use boxy
    __print_message "$level" "$msg" "$color" "$icon" "1"
}

# Regular messages (never use boxy)
print_progress() {
    local level="$1"
    local msg="$2"
    local color="$3"
    local icon="$4"
    
    # Progress messages never use boxy
    __print_message "$level" "$msg" "$color" "$icon" "0"
}

# Updated trace function
trace() {
    local msg="$1"
    
    # Never show in data view
    [[ "$(get_view_mode)" == "data" ]] && return 1
    
    # Require explicit flag
    if [[ "$opt_trace" -eq 0 ]] || [[ "$opt_debug" -eq 0 ]]; then
        __print_message "trace" "$msg" "grey" "···"
        return 0
    fi
    
    return 1
}

# Status function for user-facing state
status() {
    local msg="$1"
    __print_message "status" "$msg" "blue" "📊"
}
```

---

## Visual Language Guidelines

### Boxy Usage Guidelines

**IMPORTANT:** Boxy is for end states, results, and status summaries - NOT for every message.

#### When to Use Boxy:
- ✅ Final command results (`semv status`, `semv audit`)
- ✅ Version drift summaries
- ✅ Build completion reports
- ✅ Error summaries (multiple related errors)
- ✅ Success confirmations for major operations

#### When NOT to Use Boxy:
- ❌ Progress messages during operations
- ❌ Individual trace/debug messages
- ❌ Simple confirmations
- ❌ Intermediate calculations
- ❌ File-by-file processing updates

### Boxy Themes Mapping

| Use Case | Boxy Theme | When to Apply |
|----------|------------|---------------|
| Command Result | success/info | Final output of `do_*` functions |
| Error Summary | error | Multiple errors or critical failure |
| Status Report | neutral | `semv status`, `semv audit` output |
| Drift Warning | warning | Version mismatch summary |
| Build Dashboard | info | Build count/status overview |

### Multi-Box Layouts

```bash
# Version drift visualization
show_drift() {
    local pkg_ver="$1"
    local git_ver="$2"
    
    if [[ "$SEMV_USE_BOXY" == "1" ]]; then
        {
            echo "Package Version"
            echo "==============="
            echo "$pkg_ver"
        } | boxy --theme warning --width 30
        
        {
            echo "Git Version"
            echo "==========="
            echo "$git_ver"
        } | boxy --theme info --width 30
    else
        warn "Package: $pkg_ver"
        info "Git Tag: $git_ver"
    fi
}
```

---

## Environment Variables

```bash
# Core view controls
SEMV_VIEW="data|simple|full"  # Default: full
SEMV_USE_BOXY="0|1"           # Default: 0 (opt-in)
SEMV_TRACE_MODE="0|1"         # Default: 0 (opt-in)

# Backward compatibility
opt_trace=1                    # Set to 0 with -t flag
opt_debug=1                    # Set to 0 with -D flag
opt_quiet=1                    # Set to 0 with -q flag
```

---

## Migration Plan

### Phase 1: Core Infrastructure
1. Add view mode parsing to option handler
2. Implement `get_view_mode()` and `get_output_stream()`
3. Create `__print_message()` unified printer

### Phase 2: Message Level Fixes
1. Convert misused trace → info/status
2. Add new `status()` function
3. Update all printers to use unified system

### Phase 3: Boxy Integration
1. Add boxy wrapper functions
2. Implement themed output
3. Create dashboard views

### Phase 4: Testing
1. Test all view modes
2. Verify stderr/stdout routing
3. Validate boxy fallbacks

---

## Command Examples

```bash
# Data mode for scripting
semv get all --view=data | while IFS=: read type version file; do
    echo "Processing $type at version $version from $file"
done

# Simple mode for terminals without unicode
semv status --view=simple

# Full mode with boxy (default)
SEMV_USE_BOXY=1 semv audit

# Debug with trace messages
semv bump -t  # or semv bump -D

# Quiet mode (only errors)
semv sync --quiet
```

---

## Success Criteria
- ✅ No trace messages as final output
- ✅ Clean data mode for automation
- ✅ Consistent visual language
- ✅ Proper stderr/stdout routing
- ✅ Optional boxy enhancement
- ✅ Backward compatibility maintained

---

*Version: 1.0.0*
*Last Updated: 2025-09-01*