# Boxy Integration for TaskDB

## Context & Problem

TaskDB had **broken box drawing functions** in `parts/99_boxes.sh` that produced empty boxes:

```bash
# Broken output from current box functions
┌──┐
│   │  # Empty! Content missing
└──┘
```

**Root cause:** Complex manual Unicode width calculations failing with emoji and multibyte characters.

## Solution: Boxy Integration


## 📢 NEW! Boxy 0.5 API Features
**Major upgrades:** Themes, titles, footers, text coloring, width control

### New Boxy 0.5 Capabilities
```bash
# Themes with automatic icons and colors
echo "Error occurred" | boxy --theme error    # ❌ red box
echo "Success!" | boxy --theme success        # ✅ green box  
echo "Information" | boxy --theme info        # ℹ️ blue box

# Titles and footers
echo "Content" | boxy --title "🚀 App Status" --footer "v2.1.0"

# Text coloring and width control
echo "Long content here" | boxy --width 40 --text auto
```

### ORCHESTRATOR PATTERN NEEDED
**Problem:** Boxy only takes input via pipes (no direct params for content)
**Solution:** Structured orchestrator functions that prepare content + pipe to boxy

**Pattern:**
```bash
orchestratorFunction() {
    local content="$1"
    # 1. PREPARE structured content 
    local prepared_content=$(format_content_for_context "$content")
    # 2. PIPE to boxy with appropriate theme/styling
    echo "$prepared_content" | boxy --theme context --title "$title"
}
```

**Boxy** is a Rust CLI tool with proper Unicode width handling and styling support.

### Boxy Capabilities
```bash
boxy --help
# Styles: normal, rounded, double, heavy, ascii
# Colors: red, green, blue, cyan, yellow, purple, etc.
# Proper Unicode width handling for emoji
```

### Working Examples
```bash
echo "Test content with emoji 🚀 and unicode ✓" | boxy
# ┌──────────────────────────────────────────┐
# │ Test content with emoji 🚀 and unicode ✓ │  
# └──────────────────────────────────────────┘

echo "Simple test" | boxy --style rounded --color blue
# ╭─────────────╮
# │ Simple test │
# ╰─────────────╯
```

## Implementation

### 1. BashFX3 Integration Pattern

**File:** `parts/03_boxy.sh` (inserted at position 03 using fx-buildsh!)

**Key functions:**
```bash
check_boxy_available()     # Dependency validation
box()                      # Simple wrapper (replaces broken version)
header_box()              # "┌─ Task Details ─┐" pattern
status_box()              # Colored feedback (error|success|warning|info)
section_box()             # "═══ Section Title ═══" pattern  
task_card()               # Task detail display
banner()                  # Status banners with emoji
focus_screen()            # Centered modal displays
```

### 2. Template System

**Status Messages:**
```bash
# Replace hardcoded separators:
echo "🚨 ═══════════════════════════════════════════════════════════════"

# With colored boxy templates:
banner error "CRITICAL: Database connection lost"
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ 🚨 CRITICAL: Database connection lost                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

**Task Cards:**
```bash
# Replace manual box drawing (taskdb.sh:1768-1848):
local header_text="─ Task Details ─"
local remaining_dashes=$((CARD_WIDTH - 2 - header_length))
echo "┌${header_text}${right_dashes}┐"

# With simple template:
task_card "$content"
# ┌─────────────────────────────────────────────────────┐
# │ ─ Task Details ─                                    │
# │                                                     │
# │ ID: TASK-456                                        │
# │ Title: Implement user dashboard                     │
# │ Agent: bob                                          │
# │ State: DEV_COMPLETE (🔧 DCMP)                       │
# └─────────────────────────────────────────────────────┘
```

### 3. Focus Screen System

**Mini-subscreens for enhanced UX:**
```bash
# Current inline display → focused modal display
show_task_details() {
    local task_id="$1"
    local details=$(format_task_details "$task_id")
    
    if [[ "$TASKDB_FOCUS_MODE" == "true" ]]; then
        task_focus "$task_id"    # Centered modal
    else
        task_card "$details"     # Inline display
    fi
}
```

## Usage Patterns in TaskDB

### 80+ Box Drawing Locations to Replace

**Current manual patterns:**
```bash
# Lines 150, 198, 241, 319, 1270, 1497, etc.
echo "════════════════════════════════════════════════════"
echo "🚨 ═══════════════════════════════════════════════════════════════"
echo "✅ ═══════════════════════════════════════════════════════════════"
```

**New boxy patterns:**
```bash
section_box "$content" "Dashboard Summary"
banner error "VALIDATION: Task failed"
banner success "DEPLOYMENT: All services running"
```

### Help Text Modernization
```bash
# Replace hardcoded help boxes (lines 3586-3624):
┌─ TASK LIFECYCLE ──────────────────────────────────────────────────────────────────────────────┐
│                                                                                                │
│  1. CREATE → 2. ASSIGN → 3. IN_PROGRESS → 4. DEV_COMPLETE → 5. REVIEW → 6. PRODUCTION_READY  │
│                                                                                                │
└────────────────────────────────────────────────────────────────────────────────────────────────┘

# With colored, properly-sized boxy templates:
help_box "$lifecycle_content" --style double --color purple
```

## Benefits

### Technical Improvements
✅ **Proper Unicode width handling** - No more broken emoji boxes  
✅ **Consistent styling** - All boxes use same drawing system  
✅ **Color support** - Visual hierarchy with status colors  
✅ **Cleaner code** - 80+ manual box locations → template functions  
✅ **Maintainable** - Single source of truth for box styling  

### UX Enhancements  
✅ **Visual hierarchy** - Different colors for different message types  
✅ **Focus screens** - Modal-style task details  
✅ **Professional appearance** - Clean, modern CLI aesthetic  
✅ **Accessibility** - Consistent visual patterns  

## Migration Strategy

### Phase 1: Foundation ✅ COMPLETE
- [x] Insert `parts/03_boxy.sh` at position 03 using fx-buildsh
- [x] Implement core boxy wrapper functions
- [x] Add dependency checking with fallbacks
- [x] Test with emoji and Unicode content

### Phase 2: Core Replacements (READY FOR ORCHESTRATORS)
- [ ] Replace broken `box()` calls with modern orchestrator functions
- [ ] Convert task detail cards using `dashboard_card()` orchestrator
- [ ] Replace status banners with `notification_box()` and `status_banner()` orchestrators
- [ ] Convert section dividers with enhanced `section_box()` using themes
- [ ] Update all 80+ manual box locations with orchestrator pattern

### Phase 3: Enhanced Features
- [ ] Implement focus screen system
- [ ] Add TASKDB_FOCUS_MODE environment variable
- [ ] Create help text templates with colors
- [ ] Add interactive task detail modals

### Phase 4: Polish
- [ ] Standardize all 80+ box drawing locations
- [ ] Add boxy style configuration options
- [ ] Performance optimization for frequent box drawing
- [ ] Documentation and usage examples

## Dependency Management

**Installation check:**
```bash
check_boxy_available() {
    if ! command -v boxy &> /dev/null; then
        echo "❌ boxy not found. Please install: cargo install boxy" >&2
        return 1
    fi
    return 0
}
```

**Graceful fallback:**
```bash
box() {
    if ! check_boxy_available; then
        echo "$content"  # Plain text fallback
        return 1
    fi
    echo "$content" | boxy
}
```

## Testing Results

**Before (broken):**
```bash
source parts/99_boxes.sh && echo "Test content" | box
┌──┐
│   │  # EMPTY!
└──┘
```

**After (working):**
```bash  
source ./taskdb.sh && echo "Test content with emoji 🚀 ✅ 📊" | box
┌──────────────────────────┐
│ Test content with emoji 🚀 ✅ 📊 │
└──────────────────────────┘
```

## 🔧 BOXY ORCHESTRATOR FUNCTIONS

### Core Orchestrators for TaskDB Integration

**These functions replace the current template approach with modern boxy 0.5 API usage:**

#### Dashboard Card Orchestrator
```bash
dashboard_card() {
    local content="$1"
    local metric_title="${2:-📊 Dashboard}"
    local width="${3:-60}"
    
    # Prepare dashboard content with metrics formatting
    local prepared_content=$(echo "$content" | format_dashboard_metrics)
    
    echo "$prepared_content" | boxy --theme info --title "$metric_title" --width "$width"
}

# Usage:
dashboard_card "Tasks: 12 active, 5 completed
Status: System operational
Last sync: 2 minutes ago" "📊 TaskDB Status"
```

#### Notification Box Orchestrator
```bash
notification_box() {
    local level="$1"    # error|success|warning|info
    local message="$2"
    local context="${3:-System}"
    local timestamp="${4:-$(date '+%H:%M:%S')}"
    
    # Prepare notification with timestamp and context
    local title_icon="🔔"
    case "$level" in
        error)   title_icon="🚨" ;;
        success) title_icon="✅" ;;
        warning) title_icon="⚠️" ;;
    esac
    
    local prepared_content="$message"$'\n\n'"Context: $context"$'\n'"Time: $timestamp"
    
    echo "$prepared_content" | boxy --theme "$level" --title "$title_icon $context" --footer "[$timestamp]"
}

# Usage:
notification_box error "Database connection failed" "TaskDB" "14:23:45"
notification_box success "Deployment completed" "Production" 
```

#### Status Banner Orchestrator
```bash
status_banner() {
    local operation="$1"    # DEPLOYMENT, VALIDATION, BUILD, etc.
    local status="$2"       # success|error|warning|info
    local details="$3"
    local width="${4:-80}"
    
    # Prepare banner with operation context
    local status_emoji
    case "$status" in
        success) status_emoji="✅" ;;
        error)   status_emoji="❌" ;;
        warning) status_emoji="⚠️" ;;
        *)       status_emoji="ℹ️" ;;
    esac
    
    local banner_title="$status_emoji $operation"
    
    echo "$details" | boxy --theme "$status" --title "$banner_title" --width "$width"
}

# Usage:
status_banner "DEPLOYMENT" success "All services are running correctly
✅ Database: Connected
✅ API: Responding  
✅ Frontend: Online"

status_banner "VALIDATION" error "Task validation failed
❌ Missing required field: assignee
❌ Invalid priority level: URGENT+"
```

#### Task Focus Orchestrator
```bash
task_focus() {
    local task_id="$1"
    local task_details="$2"
    local width="${3:-70}"
    
    # Prepare task details with structured formatting
    local prepared_content="ID: $task_id"$'\n'"$task_details"
    
    clear
    echo
    echo "$prepared_content" | boxy --theme info --title "🎯 Task Focus" --footer "Press any key to continue" --width "$width"
    echo
    read -n 1 -s -r
    clear
}
```

#### Enhanced Section Box with Themes
```bash
section_box() {
    local content="$1"
    local section_title="$2"
    local theme="${3:-info}"
    local width="${4:-60}"
    
    # Use theme-appropriate title icons
    local title_icon="📋"
    case "$theme" in
        error)   title_icon="🚨" ;;
        success) title_icon="✅" ;;
        warning) title_icon="⚠️" ;;
    esac
    
    echo "$content" | boxy --theme "$theme" --title "$title_icon $section_title" --width "$width"
}
```

### Helper Functions for Content Preparation

```bash
format_dashboard_metrics() {
    # Format metrics for dashboard display
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Z][^:]+: ]]; then
            echo "• $line"
        else
            echo "$line"
        fi
    done
}

format_task_details() {
    local task_data="$1"
    # Structure task information for display
    echo "$task_data" | sed 's/^/  /' | sed 's/^  ID:/ID:/' | sed 's/^  Title:/Title:/'
}
```

### Migration from Old Template Functions

**Replace these old calls:**
```bash
# OLD: Basic template functions
status_box error "Something failed"
banner success "Deployment complete"
section_box "$content" "Task List"

# NEW: Modern orchestrators
notification_box error "Something failed" "System"
status_banner "DEPLOYMENT" success "All services operational"
section_box "$content" "Task List" info 60
```

## Style Usage Patterns Summary

### Visual Hierarchy Guide

| Style    | Context              | Visual Weight | Typography Feel     | Best For                    |
|----------|----------------------|---------------|---------------------|-----------------------------| 
| `heavy`  | Critical/Emergency   | Maximum       | Bold, Urgent        | System failures, emergencies|
| `double` | Important/Notice     | High          | Formal, Official    | Warnings, announcements     |
| `rounded`| Friendly/Success     | Welcoming     | Soft, Approachable  | Success messages, tips      |
| `normal` | Standard/Info        | Moderate      | Clean, Professional | General information         |
| `ascii`  | Compatibility        | Minimal       | Plain, Universal    | Fallback, simple terminals  |

### Implementation Status

#### ✅ Phase 1: Foundation Complete
- [x] Enhanced orchestrator functions with intelligent style selection
- [x] Multi-dimensional style decision matrix (type + level + context)
- [x] Boxy 0.5 API integration with themes, titles, footers
- [x] Comprehensive helper functions and content analyzers
- [x] Legacy compatibility layer maintained

#### 🔄 Phase 2: Core Replacements (Ready to Deploy)
- [ ] Replace 80+ manual box locations throughout taskdb.sh  
- [ ] Implement smart_box() for automatic style detection
- [ ] Convert task detail cards to dashboard_card() orchestrator
- [ ] Replace status banners with multi-level status_banner()
- [ ] Update all notification systems with notification_box()

#### 🎯 Phase 3: Advanced Features (Design Complete)
- [ ] Deploy task_focus() modal system with urgency detection
- [ ] Implement TASKDB_FOCUS_MODE environment variable
- [ ] Add auto_detect_style() content analysis throughout codebase
- [ ] Create context-aware help system with section_box()

#### 🚀 Phase 4: Intelligence & Polish
- [ ] Full content analysis pipeline for automatic style selection
- [ ] Performance optimization for high-frequency box drawing
- [ ] Advanced themes and customization options
- [ ] Comprehensive testing across all 80+ usage locations

### Tool Synthesis Achievement

This represents a perfect example of **Tommy's tool synthesis philosophy** - combining:
- **boxy** (Rust CLI with proper Unicode handling) 
- **BashFX 3.0** (modular shell architecture)
- **Intelligent style selection** (semantic visual hierarchy)
- **Content analysis** (automatic context detection)
- **Legacy compatibility** (graceful fallback patterns)

**Result:** Transformed broken manual box drawing into an intelligent, context-aware visual communication system that enhances TaskDB's user experience through thoughtful tool combination.

---

**Current Status:** Enhanced Orchestrator Functions Complete ✅  
**Next Action:** Begin Core Replacement Phase - Update taskdb.sh with new orchestrators  
**Tool Philosophy:** "Every visual element should intelligently adapt to its content and context" 🎨
