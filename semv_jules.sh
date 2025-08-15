#!/usr/bin/env bash
#
# semv-template.sh - Assembly Template for SEMV
# semv-revision: 2.0.0-dev_1
# This file shows the correct order for assembling all semv-*.sh files
#

################################################################################
#
#  SEMV Assembly Template - Manual Integration Order
#
################################################################################
# 
# To rebuild the complete semv.sh, manually append files in this exact order:
#
# 1. Main Header & Metadata (this template provides structure)
# 2. semv-config.sh       - Configuration, paths, constants, option defaults
# 3. semv-colors.sh       - Color/glyph definitions (esc.sh standards)
# 4. semv-printers.sh     - Output functions (info, warn, error, etc.)
# 5. semv-options.sh      - Flag parsing and opt_* variable setting
# 6. semv-guards.sh       - is_* validation functions
# 7. semv-git-ops.sh      - Git operations (is_repo, this_branch, etc.)
# 8. semv-version.sh      - Version parsing/comparison logic  
# 9. semv-semver.sh       - Core semver business logic
# 10. semv-commands-bump.sh   - do_bump, do_retag, do_next_semver
# 11. semv-commands-info.sh   - do_info, do_status, do_last
# 12. semv-commands-sync.sh   - do_sync, do_validate, do_drift (future)
# 13. semv-dispatch.sh        - Command routing and main()
#
################################################################################

#!/usr/bin/env bash
#
# SEMV - Semantic Version Manager  
# semv-revision: 2.0.0-dev_1
# semv-phase: Assembly Template
# semv-date: 2025-08-15
#
# A BashFX compliant tool for automated semantic versioning
# Supports Rust, JavaScript, Python, and Bash project synchronization
#
# portable: awk, sed, grep, git, sort, find, date
# builtins: printf, read, local, declare, case, if, for, while
#

#===============================================================================
#=====================================code!=====================================
#===============================================================================

################################################################################
#
#  SEMV Configuration & Constants
#
################################################################################

# Self-reference variables
readonly SEMV_PATH="${BASH_SOURCE[0]}";
readonly SEMV_EXEC="$0";

# XDG+ Compliance paths
readonly SEMV_HOME="${XDG_HOME:-$HOME/.local}/fx/semv";
readonly SEMV_CONFIG="${XDG_ETC:-$HOME/.local/etc}/fx/semv";
readonly SEMV_DATA="${XDG_DATA:-$HOME/.local/data}/fx/semv";
readonly SEMV_RC="${SEMV_HOME}/.semv.rc";

# Commit message label conventions
readonly SEMV_MAJ_LABEL="brk";    # Breaking changes -> Major bump
readonly SEMV_FEAT_LABEL="feat";  # New features -> Minor bump  
readonly SEMV_FIX_LABEL="fix";    # Bug fixes -> Patch bump
readonly SEMV_DEV_LABEL="dev";    # Development notes -> Dev build

# Build system constants
readonly SEMV_MIN_BUILD=1000;     # Minimum build number floor

# Terminal setup
export TERM=xterm-256color;

################################################################################
#
#  Default Option States
#
################################################################################

# Standard BashFX flag variables (set by options())
opt_debug=1;       # 0=enabled, 1=disabled (default off)
opt_trace=1;       # 0=enabled, 1=disabled (default off)  
opt_quiet=1;       # 0=enabled, 1=disabled (default off)
opt_force=1;       # 0=enabled, 1=disabled (default off)
opt_yes=1;         # 0=enabled, 1=disabled (default off)
opt_dev=1;         # 0=enabled, 1=disabled (default off)

# SEMV-specific option states
opt_dev_note=1;    # 0=enabled, 1=disabled (default off)
opt_build_dir=1;   # 0=enabled, 1=disabled (default off)
opt_no_cursor=1;   # 0=enabled, 1=disabled (default off)

################################################################################
#
#  Environment Variable Support
#
################################################################################

# Support NO_BUILD_CURSOR environment variable
if [[ "${NO_BUILD_CURSOR:-}" == "1" ]] || [[ "${NO_BUILD_CURSOR:-}" == "true" ]]; then
    opt_no_cursor=0;
fi

# Support QUIET_MODE, DEBUG_MODE from BashFX standards
if [[ "${QUIET_MODE:-}" == "1" ]] || [[ "${QUIET_MODE:-}" == "true" ]]; then
    opt_quiet=0;
fi

if [[ "${DEBUG_MODE:-}" == "1" ]] || [[ "${DEBUG_MODE:-}" == "true" ]]; then
    opt_debug=0;
fi

################################################################################
#
#  Configuration Validation
#
################################################################################

# Ensure XDG+ directories exist if we're in install mode
# (This will be called by lifecycle functions)
_ensure_xdg_paths() {
    local ret=1;
    
    if [[ ! -d "$SEMV_HOME" ]]; then
        mkdir -p "$SEMV_HOME" 2>/dev/null && ret=0;
    else
        ret=0;
    fi
    
    if [[ ! -d "$SEMV_CONFIG" ]]; then
        mkdir -p "$SEMV_CONFIG" 2>/dev/null || ret=1;
    fi
    
    if [[ ! -d "$SEMV_DATA" ]]; then
        mkdir -p "$SEMV_DATA" 2>/dev/null || ret=1;
    fi
    
    return "$ret";
}

#-------------------------------------------------------------------------------
# Colors & Glyphs
#-------------------------------------------------------------------------------

################################################################################
#
#  BashFX Standard Colors (from esc.sh)
#
################################################################################

# Core colors
readonly red=$'\x1B[38;5;197m';      # Was: $(tput setaf 202)
readonly green=$'\x1B[32m';          # Was: $(tput setaf 2)  
readonly blue=$'\x1B[36m';           # Was: $(tput setaf 12)
readonly orange=$'\x1B[38;5;214m';   # Was: $(tput setaf 214)
readonly yellow=$'\x1B[33m';         # Was: $(tput setaf 11)
readonly purple=$'\x1B[38;5;213m';   # Was: $(tput setaf 213)
readonly grey=$'\x1B[38;5;244m';     # Was: $(tput setaf 247)

# Extended colors
readonly blue2=$'\x1B[38;5;39m';
readonly cyan=$'\x1B[38;5;14m';
readonly white=$'\x1B[38;5;248m';
readonly white2=$'\x1B[38;5;15m';
readonly grey2=$'\x1B[38;5;240m';

# Control sequences
readonly revc=$'\x1B[7m';            # Reverse video - was: $(tput rev)
readonly bld=$'\x1B[1m';             # Bold
readonly x=$'\x1B[0m';               # Reset all attributes - was: $(tput sgr0)
readonly eol=$'\x1B[K';              # Erase to end of line

################################################################################
#
#  BashFX Standard Glyphs (from esc.sh)
#
################################################################################

# Status indicators
readonly pass=$'\u2713';             # ✓ - was: "\xE2\x9C\x93"
readonly fail=$'\u2715';             # ✕ - was: "${red}\xE2\x9C\x97"  
readonly delta=$'\u25B3';            # △ - was: "\xE2\x96\xB3"
readonly star=$'\u2605';             # ★ - was: "\xE2\x98\x85"

# Progress and activity  
readonly lambda=$'\u03BB';           # λ - was: "\xCE\xBB"
readonly idots=$'\u2026';            # … - was: "\xE2\x80\xA6"
readonly bolt=$'\u21AF';             # ↯ - was: "\xE2\x86\xAF"
readonly spark=$'\u27E1';            # ⟡ - was: "\xe2\x9f\xa1"

# Utility characters
readonly tab=$'\t';
readonly nl=$'\n';
readonly sp=' ';

################################################################################
#
#  SEMV-Specific Color Combinations
#
################################################################################

# Pre-composed colored glyphs for common patterns
readonly fail_red="${red}${fail}${x}";      # Red X for errors
readonly pass_green="${green}${pass}${x}";  # Green checkmark for success
readonly warn_orange="${orange}${delta}${x}"; # Orange triangle for warnings
readonly info_blue="${blue}${spark}${x}";   # Blue spark for info

################################################################################
#
#  Legacy Compatibility Mappings  
#
################################################################################

# Maintain compatibility with original semv variable names
# These can be removed in Phase 2 after function updates
readonly inv="$revc";                # Backwards compatibility for "inv"

#-------------------------------------------------------------------------------
# Printers & Output
#-------------------------------------------------------------------------------

################################################################################
#
#  Core Printer Helper
#
################################################################################

__printf() {
    local text="$1";
    local color="${2:-white2}";
    local prefix="${!3:-}";
    local ret=1;
    
    if [[ -n "$text" ]]; then
        printf "${prefix}${!color}%b${x}" "$text" >&2;
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  Standard BashFX Message Functions
#
################################################################################

# Info messages (silenced unless -d flag)
info() {
    local msg="$1";
    local force="${2:-1}";
    local ret=1;
    
    if [[ "$force" -eq 0 ]] || [[ "$opt_debug" -eq 0 ]]; then
        __printf "${info_blue} ${msg}\n" "blue";
        ret=0;
    fi
    
    return "$ret";
}

# Warning messages (silenced unless -d flag)  
warn() {
    local msg="$1";
    local force="${2:-1}";
    local ret=1;
    
    if [[ "$force" -eq 0 ]] || [[ "$opt_debug" -eq 0 ]]; then
        __printf "${warn_orange} ${msg}\n" "orange";
        ret=0;
    fi
    
    return "$ret";
}

# Success messages (silenced unless -d flag)
okay() {
    local msg="$1"; 
    local force="${2:-1}";
    local ret=1;
    
    if [[ "$force" -eq 0 ]] || [[ "$opt_debug" -eq 0 ]]; then
        __printf "${pass_green} ${msg}\n" "green";
        ret=0;
    fi
    
    return "$ret";
}

# Trace messages (silenced unless -t flag)
trace() {
    local msg="$1";
    local ret=1;
    
    if [[ "$opt_trace" -eq 0 ]]; then
        __printf "${idots} ${msg}\n" "grey";
        ret=0;
    fi
    
    return "$ret";
}

# Error messages (always visible unless -q flag)
error() {
    local msg="$1";
    local ret=1;
    
    if [[ "$opt_quiet" -ne 0 ]]; then
        __printf "${fail_red} ${msg}\n" "red";
        ret=0;
    fi
    
    return "$ret";
}

# Fatal errors (always visible, exits script)
fatal() {
    local msg="$1";
    local code="${2:-1}";
    
    trap - EXIT;
    __printf "\n${fail_red} ${msg}\n" "red";
    exit "$code";
}

################################################################################
#
#  User Interaction Functions
#
################################################################################

__confirm() {
    local prompt="$1";
    local ret=1;
    local answer;
    local src;
    
    # Auto-yes mode check
    if [[ "$opt_yes" -eq 0 ]]; then
        __printf "${bld}${green}auto yes${x}\n";
        return 0;
    fi
    
    __printf "${prompt}? > " "white2";
    
    # Determine input source
    if [[ -n "${BASH_SOURCE}" ]]; then
        src="/dev/stdin";
    else
        src="/dev/tty";
    fi
    
    while read -r -n 1 -s answer < "$src"; do
        if [[ $? -eq 1 ]]; then
            exit 1;
        fi
        
        # Only accept valid responses
        if [[ ! "$answer" =~ [YyNn10tf+\-q] ]]; then
            continue;
        fi
        
        case "$answer" in
            [Yyt1+])
                __printf "${bld}${green}yes${x}";
                ret=0;
                ;;
            [Nnf0\-])
                __printf "${bld}${red}no${x}";
                ret=1;
                ;;
            [q])
                __printf "${bld}${purple}quit${x}\n";
                ret=1;
                exit 1;
                ;;
        esac
        break;
    done
    
    __printf "\n";
    return "$ret";
}

__prompt() {
    local msg="$1";
    local default="$2";
    local answer;
    
    if [[ "$opt_yes" -eq 1 ]]; then
        read -p "$msg --> " answer;
        if [[ -n "$answer" ]]; then
            echo "$answer";
        else
            echo "$default";
        fi
    else
        echo "$default";
    fi
}

################################################################################
#
#  Legacy Compatibility Functions
#
################################################################################

# Maintain backwards compatibility during migration
# These will be removed in Phase 2

identify() {
    local level="${#FUNCNAME[@]}";
    local f2="${FUNCNAME[2]}";
    
    if [[ "$opt_dev" -eq 0 ]]; then
        trace "⟡────[${white2}${FUNCNAME[1]}${grey}]${grey2}<-$f2";
    fi
}

#-------------------------------------------------------------------------------
# Options & Flag Parsing
#-------------------------------------------------------------------------------

################################################################################
#
#  options - Parse command-line flags and set opt_* variables
#
################################################################################
# Arguments: All command-line arguments ("$@")
# Returns: 0 on success, 1 on invalid flag
# Local Variables: this, next, opts, i
# Sets: opt_debug, opt_trace, opt_quiet, opt_force, opt_yes, opt_dev, etc.

options() {
    local this;
    local next;
    local opts=("$@");
    local i;
    local ret=0;

    for ((i=0; i<${#opts[@]}; i++)); do
        this="${opts[i]}";
        next="${opts[i+1]}";
        
        case "$this" in
            --debug|-d)
                opt_debug=0;
                opt_quiet=1;
                ;;
            --trace|-t)
                opt_trace=0;
                opt_debug=0;
                ;;
            --quiet|-q)
                opt_quiet=0;
                opt_debug=1;
                opt_trace=1;
                ;;
            --force|-f)
                opt_force=0;
                ;;
            --yes|-y)
                opt_yes=0;
                ;;
            --dev|-D)
                # Master developer flag - enables debug and trace
                opt_dev=0;
                opt_debug=0;
                opt_trace=0;
                opt_quiet=1;
                ;;
            --dev-note|-N)
                opt_dev_note=0;
                ;;
            --build-dir|-B)
                opt_build_dir=0;
                ;;
            --no-cursor)
                opt_no_cursor=0;
                ;;
            -*)
                error "Invalid flag [$this]";
                ret=1;
                ;;
            *)
                # Non-flag arguments are passed through
                ;;
        esac
    done
    
    return "$ret";
}

################################################################################
#
#  _filter_args - Remove flags from argument list
#
################################################################################
# Arguments: All command-line arguments ("$@")
# Returns: 0 on success
# Local Variables: arg, filtered_args
# Outputs: Non-flag arguments to stdout

_filter_args() {
    local arg;
    local filtered_args=();
    
    for arg in "$@"; do
        case "$arg" in
            -*)
                # Skip flags
                ;;
            *)
                filtered_args+=("$arg");
                ;;
        esac
    done
    
    printf '%s\n' "${filtered_args[@]}";
    return 0;
}

#-------------------------------------------------------------------------------
# Guards & Validation
#-------------------------------------------------------------------------------
# From parts/semv_guards.sh
is_repo() { git rev-parse --is-inside-work-tree > /dev/null 2>&1; }
is_main() { local branch; branch=$(this_branch); if [[ -n "$branch" ]] && [[ "$branch" == "main" || "$branch" == "master" ]]; then return 0; fi; return 1; }
has_commits() { if is_repo && git rev-parse HEAD > /dev/null 2>&1; then return 0; fi; return 1; }
has_semver() { git tag --list | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+$'; }
is_not_staged() { git diff --exit-code > /dev/null 2>&1; }
is_dev() { [[ "$opt_dev" -eq 0 ]] || [[ "${DEV_MODE:-}" == "1" ]]; }
is_quiet() { [[ "$opt_quiet" -eq 0 ]] || [[ "${QUIET_MODE:-}" == "1" ]]; }
is_force() { [[ "$opt_force" -eq 0 ]]; }
command_exists() { local cmd="$1"; type "$cmd" &> /dev/null; }
function_exists() { local func="$1"; [[ -n "$func" ]] && declare -F "$func" >/dev/null; }
is_empty() { local var="$1"; [[ -z "$var" ]]; }
is_valid_semver() { local version="$1"; [[ "$version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; }
is_file() { local path="$1"; [[ -f "$path" && -r "$path" ]]; }
is_dir() { local path="$1"; [[ -d "$path" ]]; }
is_writable() { local path="$1"; [[ -w "$path" ]]; }

#-------------------------------------------------------------------------------
# Git Operations
#-------------------------------------------------------------------------------
# From parts/semv_git_ops.sh
this_branch() { git branch --show-current; }
this_user() { git config user.name | tr -d ' '; }
this_project() { basename "$(git rev-parse --show-toplevel)"; }
which_main() { local ret=1; if has_commits; then git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'; ret=0; fi; return "$ret"; }
last_commit() { local ret=1; if has_commits; then if git rev-parse HEAD >/dev/null 2>&1; then git show -s --format=%ct HEAD; ret=0; fi; fi; if [[ "$ret" -eq 1 ]]; then echo "0"; fi; return "$ret"; }
since_last() { local tag="$1"; local label="$2"; local count; local ret=1; if is_repo; then count=$(git log --pretty=format:"%s" "${tag}"..HEAD | grep -cE "^${label}:"); echo "$count"; trace "[$count] [$label] changes since [$tag]"; ret=0; else error "Error. current dir not a git repo."; fi; return "$ret"; }
__git_list_tags() { git show-ref --tags | cut -d '/' -f 3-; }
__git_latest_tag() { local latest; local ret=1; if is_repo; then latest=$(git tag | sort -V | tail -n1); if [[ -n "$latest" ]]; then echo "$latest"; ret=0; fi; fi; return "$ret"; }
__git_latest_semver() { local latest; local ret=1; if has_semver; then latest=$(git tag --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1); if [[ -n "$latest" ]]; then echo "$latest"; ret=0; fi; fi; return "$ret"; }
__git_tag_create() { local tag="$1"; local msg="$2"; local ret=1; if [[ -n "$tag" ]] && [[ -n "$msg" ]]; then git tag -a "$tag" -m "$msg"; ret=$?; fi; return "$ret"; }
__git_tag_delete() { local tag="$1"; local ret=1; if [[ -n "$tag" ]]; then git tag -d "$tag"; ret=$?; fi; return "$ret"; }
__git_push_tags() { local force_flag=""; local ret=1; if [[ "$1" == "force" ]]; then force_flag="--force"; fi; git push --tags $force_flag; ret=$?; return "$ret"; }
__git_build_count() { local count; count=$(git rev-list HEAD --count); count=$((count + SEMV_MIN_BUILD)); echo "$count"; return 0; }
__git_remote_build_count() { local count; count=$(git rev-list origin/main --count 2>/dev/null || echo 0); count=$((count + SEMV_MIN_BUILD)); echo "$count"; return 0; }
__git_status_count() { local count; count=$(git status --porcelain | wc -l | awk '{print $1}'); echo "$count"; return 0; }
__git_fetch_tags() { local before_fetch; local after_fetch; local output; local ret; before_fetch=$(git tag); output=$(git fetch --tags 2>&1); ret=$?; after_fetch=$(git tag); if [[ "$before_fetch" != "$after_fetch" ]]; then okay "New tag changes found."; else info "No new tags."; fi; return "$ret"; }

#-------------------------------------------------------------------------------
# Version Logic
#-------------------------------------------------------------------------------
# From parts/semv_version.sh
split_vers() { local vers_str="$1"; local ret=1; if [[ -z "$vers_str" ]]; then return 1; fi; if [[ $vers_str =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; then major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}; extra=${BASH_REMATCH[4]}; printf "%s %s %s %s\n" "$major" "$minor" "$patch" "$extra"; ret=0; fi; return "$ret"; }
_validate_version_format() { local version="$1"; [[ "$version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; }
do_compare_versions() { local v1="$1"; local op="$2"; local v2="$3"; local result; local ret=1; if [[ -z "$v1" ]] || [[ -z "$v2" ]] || [[ -z "$op" ]]; then error "Usage: do_compare_versions <version1> <operator> <version2>"; return 1; fi; if ! _validate_version_format "$v1"; then error "Invalid version format: $v1"; return 1; fi; if ! _validate_version_format "$v2"; then error "Invalid version format: $v2"; return 1; fi; if [[ "$v1" == "$v2" ]]; then case "$op" in '='|'=='|'>='|'<=') printf "true\n"; ret=0; ;; *) printf "false\n"; ret=1; ;; esac; return "$ret"; fi; local OLD_IFS="$IFS"; IFS='.'; local -a ver1=($v1) ver2=($v2); IFS="$OLD_IFS"; ver1[0]=${ver1[0]#v}; ver2[0]=${ver2[0]#v}; local i; local len1=${#ver1[@]}; local len2=${#ver2[@]}; local max_len=$(( len1 > len2 ? len1 : len2 )); for ((i = 0; i < max_len; i++)); do local c1=${ver1[i]:-0}; local c2=${ver2[i]:-0}; c1=${c1%%-*}; c2=${c2%%-*}; if (( c1 > c2 )); then case "$op" in '>'|'>='|'!=') printf "true\n"; ret=0; ;; *) printf "false\n"; ret=1; ;; esac; return "$ret"; fi; if (( c1 < c2 )); then case "$op" in '<'|'<='|'!=') printf "true\n"; ret=0; ;; *) printf "false\n"; ret=1; ;; esac; return "$ret"; fi; done; case "$op" in '='|'=='|'>='|'<=') printf "true\n"; ret=0; ;; *) printf "false\n"; ret=1; ;; esac; return "$ret"; }
do_is_greater() { local version_b="$1"; local version_a="$2"; local result; local ret=1; if [[ -z "$version_a" ]] || [[ -z "$version_b" ]]; then error "Invalid comparison - missing version"; return 1; fi; trace "$version_b > $version_a ?"; result=$(do_compare_versions "$version_b" ">" "$version_a"); if [[ "$result" == "true" ]]; then trace "$version_b > $version_a ✓"; ret=0; else trace "$version_b <= $version_a ✗"; ret=1; fi; return "$ret"; }
do_test_semver() { local version="$1"; local parts; local ret=1; if [[ -z "$version" ]]; then error "Usage: do_test_semver <version>"; return 1; fi; info "Testing version format: $version"; parts=$(split_vers "$version"); ret=$?; if [[ "$ret" -eq 0 ]]; then local -a components=($parts); okay "Valid semantic version format"; info "Major: ${components[0]}"; info "Minor: ${components[1]}"; info "Patch: ${components[2]}"; if [[ -n "${components[3]}" ]]; then info "Extra: ${components[3]}"; fi; printf "%s\n" "$parts"; else error "Invalid semantic version format"; error "Expected format: v1.2.3 or v1.2.3-suffix"; fi; return "$ret"; }

#-------------------------------------------------------------------------------
# Semver Core Logic
#-------------------------------------------------------------------------------
# From parts/semv_semver.sh
do_latest_tag() { local latest; local ret=1; if is_repo; then latest=$(__git_latest_tag); if [[ -n "$latest" ]]; then printf "%s\n" "$latest"; ret=0; fi; fi; return "$ret"; }
do_latest_semver() { local latest; local ret=1; if has_semver; then latest=$(__git_latest_semver); if [[ -n "$latest" ]]; then printf "%s\n" "$latest"; ret=0; else error "No semver tags found"; fi; else error "No semver tags found"; fi; return "$ret"; }
do_change_count() { local tag="${1:-$(do_latest_tag)}"; local break_count; local feat_count; local fix_count; local dev_count; local ret=1; if [[ -z "$tag" ]]; then error "No tag specified and no tags found"; return 1; fi; b_major=0; b_minor=0; b_patch=0; break_count=$(since_last "$tag" "$SEMV_MAJ_LABEL"); feat_count=$(since_last "$tag" "$SEMV_FEAT_LABEL"); fix_count=$(since_last "$tag" "$SEMV_FIX_LABEL"); dev_count=$(since_last "$tag" "$SEMV_DEV_LABEL"); build_s=$(__git_build_count); note_s="$dev_count"; trace "Changes since $tag: brk=$break_count feat=$feat_count fix=$fix_count dev=$dev_count"; if [[ "$break_count" -ne 0 ]]; then trace "Found breaking changes - major bump"; b_major=1; b_minor=0; b_patch=0; ret=0; elif [[ "$feat_count" -ne 0 ]]; then trace "Found new features - minor bump"; b_minor=1; b_patch=0; ret=0; elif [[ "$fix_count" -ne 0 ]]; then trace "Found bug fixes - patch bump"; b_patch=1; ret=0; elif [[ "$dev_count" -ne 0 ]]; then trace "Found dev notes - no version bump"; ret=0; fi; return "$ret"; }
do_next_semver() { local force="${1:-1}"; local tag; local parts; local major; local minor; local patch; local extra; local new_version; local tail_suffix=""; local ret=1; tag=$(do_latest_tag); if [[ -z "$tag" ]]; then error "No tags found to bump from"; return 1; fi; parts=$(split_vers "$tag"); if [[ $? -ne 0 ]]; then error "Invalid version format: $tag"; return 1; fi; local -a components=($parts); major="${components[0]}"; minor="${components[1]}"; patch="${components[2]}"; extra="${components[3]}"; if ! do_change_count "$tag"; then if [[ "$opt_dev_note" -eq 0 ]]; then error "No changes since last tag ($tag)"; return 1; fi; fi; major=$((major + b_major)); minor=$((minor + b_minor)); patch=$((patch + b_patch)); if [[ "$b_major" -eq 1 ]]; then minor=0; patch=0; elif [[ "$b_minor" -eq 1 ]]; then patch=0; fi; new_version="v${major}.${minor}.${patch}"; if [[ "$opt_dev_note" -eq 0 ]]; then if [[ "$note_s" -ne 0 ]]; then trace "Dev notes found - adding dev suffix"; tail_suffix="-dev_${note_s}"; else trace "Clean build - adding build suffix"; tail_suffix="-build_${build_s}"; fi; new_version="${new_version}${tail_suffix}"; fi; trace "Version calculation: $tag -> $new_version"; if [[ "$force" -ne 0 ]] && [[ "$note_s" -ne 0 ]] && [[ "$opt_dev_note" -eq 1 ]]; then warn "There are [$note_s] dev notes and --dev flag is disabled"; info "Current: $tag"; info "Next: $new_version"; warn "You should only bump versions if dev notes are resolved"; if ! __confirm "Continue with version bump"; then error "Version bump cancelled"; return 1; fi; fi; printf "%s\n" "$new_version"; ret=0; return "$ret"; }
do_build_file() { local filename="${1:-build.inf}"; local dest; local ret=1; if [[ "$opt_no_cursor" -eq 0 ]]; then trace "Build cursor disabled - skipping file generation"; return 0; fi; if [[ "$opt_build_dir" -eq 0 ]]; then if [[ ! -d "./build" ]]; then mkdir -p "./build"; fi; dest="./build/${filename}"; else dest="./${filename}"; fi; if __print_build_info "$dest"; then okay "Build file generated: $dest"; if [[ "$opt_trace" -eq 0 ]]; then cat "$dest"; fi; ret=0; else error "Failed to generate build file"; fi; return "$ret"; }
__print_build_info() { local dest="$1"; local version; local build; local branch; local semver; local ret=1; if [[ -z "$dest" ]]; then return 1; fi; version=$(do_latest_tag); build=$(__git_build_count); branch=$(this_branch); semver=$(do_next_semver 0 2>/dev/null || echo "$version"); cat > "$dest" << EOF
DEV_VERS=${version}
DEV_BUILD=${build}
DEV_BRANCH=${branch}
DEV_DATE=$(date +%D)
DEV_SEMVER=${semver}
SYNC_SOURCE=
SYNC_VERSION=
SYNC_DATE=
EOF
if [[ -f "$dest" ]] && [[ -s "$dest" ]]; then ret=0; fi; return "$ret"; }

#-------------------------------------------------------------------------------
# Command Functions
#-------------------------------------------------------------------------------
# From parts/semv_commands.sh & semv_sync_integration.sh
do_bump() {
    local force="${1:-1}";
    local -a detected_types;
    local has_sync_sources=0;
    local latest;
    local new_version;
    local ret=1;

    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi

    info "Starting enhanced bump with sync integration...";

    # Detect sync sources
    mapfile -t detected_types < <(_detect_project_type 2>/dev/null);
    if [[ "${#detected_types[@]}" -gt 0 ]]; then
        has_sync_sources=1;
        info "Sync sources detected: ${detected_types[*]}";
    fi

    # Pre-bump validation and sync
    if [[ "$has_sync_sources" -eq 1 ]]; then
        info "Performing pre-bump sync...";
        if ! do_validate; then
            warn "Version drift detected before bump";
            if [[ "$force" -ne 0 ]] && ! __confirm "Continue with version drift"; then
                error "Bump cancelled due to version drift";
                return 1;
            fi
            if __confirm "Auto-sync before bump"; then
                if ! do_sync; then
                    error "Failed to sync before bump";
                    return 1;
                fi
            fi
        fi
    fi

    # Perform the version bump
    latest=$(do_latest_tag);
    new_version=$(do_next_semver "$force");
    ret=$?;

    if [[ "$ret" -eq 0 ]] && [[ -n "$new_version" ]]; then
        trace "Bump: $latest -> $new_version";
        if _do_retag "$new_version" "$latest"; then
            okay "Git version bumped successfully: $new_version";

            # Post-bump sync
            if [[ "$has_sync_sources" -eq 1 ]]; then
                info "Performing post-bump sync...";
                if do_sync; then
                    okay "All sources synced to: $new_version";
                else
                    warn "Post-bump sync failed - manual sync may be required";
                fi
            fi
            ret=0;
        else
            error "Failed to create version tag";
            ret=1;
        fi
    else
        error "Failed to calculate next version";
    fi

    return "$ret";
}
_do_retag() { local new_tag="$1"; local current_tag="$2"; local note; local ret=1; if [[ -z "$new_tag" ]]; then error "Missing new tag"; return 1; fi; if ! has_semver || ! is_main; then error "Can only retag on main branch with existing semver"; return 1; fi; if ! do_is_greater "$new_tag" "$current_tag"; then error "New version ($new_tag) is not greater than current ($current_tag)"; return 1; fi; if ! is_not_staged; then if __confirm "You have uncommitted changes. Commit them with this tag"; then git add --all; git commit -m "auto: adding changes for retag @${new_tag}"; else error "Cancelled due to uncommitted changes"; return 1; fi; fi; note=$(__prompt "Tag message" "auto tag bump"); if __git_tag_create "$new_tag" "$note"; then info "Created tag: $new_tag"; if __git_push_tags "force"; then okay "Pushed tags to remote"; if __confirm "Push commits for $new_tag and main to origin"; then git push origin "$new_tag"; git push origin main; okay "Pushed commits to remote"; fi; ret=0; else error "Failed to push tags"; fi; else error "Failed to create tag"; fi; return "$ret"; }

do_days_ago() {
    local last;
    local now;
    local diff;
    local days;
    
    last=$(last_commit);
    now=$(date +%s);
    diff=$((now - last));
    days=$((diff / 86400));
    
    printf "%d\n" "$days";
    return 0;
}

do_since_pretty() {
    local last;
    local now;
    local midnight;
    local diff;
    local days;
    local hours;
    local minutes;
    local seconds;
    local daystr;
    
    last=$(last_commit);
    now=$(date +%s);
    
    # Get midnight timestamp
    if [[ "$(uname)" == "Darwin" ]]; then
        midnight=$(date -v0H -v0M -v0S +%s);
    else
        midnight=$(date --date="today 00:00:00" +%s);
    fi
    
    diff=$((now - last));
    days=$((diff / 86400));
    hours=$(((diff / 3600) % 24));
    minutes=$(((diff / 60) % 60));
    seconds=$((diff % 60));
    
    if [[ "$days" -eq 0 ]]; then
        if [[ "$last" -lt "$midnight" ]]; then
            daystr="Yesterday";
        else
            daystr="Today";
        fi
    elif [[ "$days" -eq 1 ]]; then
        daystr="$days day";
    else
        daystr="$days days";
    fi
    
    if [[ "$hours" -ne 0 ]]; then
        daystr="$daystr $hours hrs";
    fi
    
    if [[ "$minutes" -ne 0 ]]; then
        daystr="$daystr $minutes min";
    fi
    
    if [[ "$seconds" -ne 0 ]]; then
        daystr="$daystr $seconds sec";
    fi
    
    if [[ "$days" -eq 0 ]] && [[ "$hours" -eq 0 ]] && [[ "$minutes" -eq 0 ]] && [[ "$seconds" -lt 30 ]]; then
        daystr="Just now";
    fi
    
    printf "%s\n" "$daystr";
    return 0;
}

do_info() {
    local user;
    local branch;
    local main_branch;
    local project;
    local build;
    local remote_build;
    local changes;
    local since;
    local days;
    local semver;
    local next;
    local msg="";
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    # Gather repository information
    user=$(this_user);
    branch=$(this_branch);
    main_branch=$(which_main);
    project=$(this_project);
    
    if [[ -z "$user" ]]; then
        user="${red}-unset-${x}";
    fi
    
    if has_commits; then
        build=$(__git_build_count);
        remote_build=$(__git_remote_build_count);
        changes=$(__git_status_count);
        since=$(do_since_pretty);
        days=$(do_days_ago);
        
        # Format change count
        if [[ "$changes" -gt 0 ]]; then
            changes="${green}Edits +$changes${x}";
        else
            changes="${grey}none${x}";
        fi
        
        # Format build comparison
        if [[ "$remote_build" -gt "$build" ]]; then
            remote_build="${green}${remote_build}${x}";
        elif [[ "$remote_build" -eq "$build" ]]; then
            # Equal builds - no highlighting
            :;
        else
            build="${green}${build}${x}";
        fi
        
        # Build info message
        msg+="~~ Repository Status ~~\n";
        msg+="${spark} User: [${user}]\n";
        msg+="${spark} Repo: [${project}] [${branch}] [${main_branch}]\n";
        msg+="${spark} Changes: [${changes}]\n";
        msg+="${spark} Build: [${build}:${remote_build}]\n";
        msg+="${spark} Last: [${days} days] ${since}\n";
        
        # Version information
        if has_semver; then
            semver=$(do_latest_semver);
            next=$(do_next_semver 0 2>/dev/null);
            
            if [[ -z "$next" ]]; then
                next="${red}-none-${x}";
            elif do_is_greater "$next" "$semver"; then
                next="${green} -> ${next}${x}";
            elif [[ "$next" == "$semver" ]]; then
                next="<-same-> ${next}";
            fi
            
            msg+="${spark} Version: [${semver} ${next}]";
        else
            msg+="${spark} Version: [${red}-unset-${x}]";
        fi
        
        printf "%b\n" "$msg" >&2;
    else
        warn "Repository: [${user}] [${project}] [${branch}] [${red}no commits${x}]";
    fi
    
    # Add sync information if available
    local -a detected_types;
    local has_sync_sources=0;
    local sync_status;
    mapfile -t detected_types < <(_detect_project_type);
    if [[ "${#detected_types[@]}" -gt 0 ]]; then
        has_sync_sources=1;
        
        printf "\n" >&2;
        info "~~ Sync Status ~~";
        info "Detected sources: ${detected_types[*]}";
        
        # Check sync status
        if do_validate >/dev/null 2>&1; then
            sync_status="${green}✓ In Sync${x}";
        else
            sync_status="${orange}⚠ Drift Detected${x}";
        fi
        
        printf "%b %s %s\n" "${spark}" "Sync Status:" "$sync_status" >&2;
        
        # Show last sync info from cursor
        _show_last_sync_info;
    else
        printf "\n" >&2;
        info "~~ Sync Status ~~";
        info "No sync sources detected";
    fi
    
    return 0;
}
do_pending() { local latest; local label="${1:-any}"; local changes; local ret=1; if ! is_repo; then error "Not in a git repository"; return 1; fi; latest=$(do_latest_tag); if [[ -n "$latest" ]]; then if [[ "$label" != "any" ]]; then changes=$(git log "${latest}"..HEAD --grep="^${label}:" --pretty=format:"%h - %s"); else changes=$(git log "${latest}"..HEAD --pretty=format:"%h - %s"); fi; if [[ -n "$changes" ]]; then warn "Found changes ($label) since $latest:"; printf "%s\n" "$changes" >&2; ret=0; else okay "No labeled ($label:) commits after $latest"; ret=1; fi; else error "No tags found. Try 'semv new' to initialize"; ret=1; fi; return "$ret"; }
do_last() { local days; local since; local semver; if ! is_repo; then error "Not in a git repository"; return 1; fi; days=$(do_days_ago); since=$(do_since_pretty); semver=$(do_latest_tag); if [[ "$days" -lt 7 ]]; then okay "Last commit was $since"; elif [[ "$days" -lt 30 ]]; then warn "Last commit was $since"; else error "Last commit was $since"; fi; return 0; }
do_status() { local count; if ! is_repo; then error "Not in a git repository"; return 1; fi; count=$(__git_status_count); printf "%d\n" "$count"; if [[ "$count" -gt 0 ]]; then return 0; else return 1; fi; }
do_fetch_tags() { if ! is_repo; then error "Not in a git repository"; return 1; fi; __git_fetch_tags; }
do_tags() { local tags; if ! is_repo; then error "Not in a git repository"; return 1; fi; tags=$(__git_list_tags); info "Repository tags:"; printf "%s\n" "$tags" >&2; return 0; }
do_inspect() { info "Available functions:"; declare -F | grep 'do_' | awk '{print $3}' >&2; info "Dispatch mappings:"; info "(Dispatch table inspection not implemented yet)"; return 0; }
do_label_help() { local msg=""; msg+="~~ SEMV Commit Labels ~~\n"; msg+="${spark} ${green}brk:${x}  -> Breaking changes [Major]\n"; msg+="${spark} ${green}feat:${x} -> New features [Minor]\n"; msg+="${spark} ${green}fix:${x}  -> Bug fixes [Patch]\n"; msg+="${spark} ${green}dev:${x}  -> Development notes [Dev Build]\n"; printf "%b\n" "$msg" >&2; return 0; }
do_auto() { local path="$1"; local cmd="$2"; error "Auto mode not implemented yet"; return 1; }

#-------------------------------------------------------------------------------
# Sync and Workflow Commands
#-------------------------------------------------------------------------------
# From parts/semv_sync_detect.sh
_detect_project_type() { local -a detected_types=(); local ret=1; if [[ -f "Cargo.toml" ]]; then detected_types+=("rust"); trace "Detected Rust project (Cargo.toml found)"; ret=0; fi; if [[ -f "package.json" ]]; then detected_types+=("js"); trace "Detected JavaScript project (package.json found)"; ret=0; fi; if [[ -f "pyproject.toml" ]]; then detected_types+=("python"); trace "Detected Python project (pyproject.toml found)"; ret=0; fi; if _detect_bash_project; then detected_types+=("bash"); trace "Detected Bash project (script with version meta found)"; ret=0; fi; PROJECT_TYPES=("${detected_types[@]}"); if [[ "${#detected_types[@]}" -gt 0 ]]; then printf "%s\n" "${detected_types[*]}"; fi; return "$ret"; }
_detect_bash_project() { local -a script_files; local file; mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null); for file in "${script_files[@]}"; do if [[ -f "$file" ]] && grep -q "^# version:" "$file" 2>/dev/null; then trace "Found bash script with version meta: $file"; return 0; fi; done; return 1; }
_validate_project_structure() { local -a rust_files; local -a js_files; local -a python_files; local ret=0; mapfile -t rust_files < <(find . -maxdepth 1 -name "Cargo.toml" 2>/dev/null); if [[ "${#rust_files[@]}" -gt 1 ]]; then error "Multiple Cargo.toml files found in root directory"; ret=1; fi; mapfile -t js_files < <(find . -maxdepth 1 -name "package.json" 2>/dev/null); if [[ "${#js_files[@]}" -gt 1 ]]; then error "Multiple package.json files found in root directory"; ret=1; fi; mapfile -t python_files < <(find . -maxdepth 1 -name "pyproject.toml" 2>/dev/null); if [[ "${#python_files[@]}" -gt 1 ]]; then error "Multiple pyproject.toml files found in root directory"; ret=1; fi; if [[ "$ret" -eq 1 ]]; then error "Project structure has conflicts - cannot determine single version source"; fi; return "$ret"; }
_get_project_version() { local project_type="$1"; local version; local ret=1; if [[ -z "$project_type" ]]; then error "Project type required"; return 1; fi; case "$project_type" in rust) version=$(__parse_cargo_version); ret=$?; ;; js) version=$(__parse_package_version); ret=$?; ;; python) version=$(__parse_pyproject_version); ret=$?; ;; bash) version=$(__parse_bash_version); ret=$?; ;; *) error "Unsupported project type: $project_type"; return 1; ;; esac; if [[ "$ret" -eq 0 ]] && [[ -n "$version" ]]; then printf "%s\n" "$version"; else error "Failed to extract version from $project_type project"; fi; return "$ret"; }
is_rust_project() { [[ -f "Cargo.toml" ]]; }
is_js_project() { [[ -f "package.json" ]]; }
is_python_project() { [[ -f "pyproject.toml" ]]; }
is_bash_project() { _detect_bash_project; }
has_multiple_project_types() { local -a detected_types; if [[ "${#PROJECT_TYPES[@]}" -gt 0 ]]; then detected_types=("${PROJECT_TYPES[@]}"); else mapfile -t detected_types < <(_detect_project_type); fi; [[ "${#detected_types[@]}" -gt 1 ]]; }
get_primary_project_type() { local -a detected_types; local primary_type; if [[ "${#PROJECT_TYPES[@]}" -eq 0 ]]; then mapfile -t detected_types < <(_detect_project_type); PROJECT_TYPES=("${detected_types[@]}"); else detected_types=("${PROJECT_TYPES[@]}"); fi; case "${#detected_types[@]}" in 0) error "No supported project types detected"; return 1; ;; 1) primary_type="${detected_types[0]}"; trace "Single project type detected: $primary_type"; ;; *) if [[ " ${detected_types[*]} " =~ " rust " ]]; then primary_type="rust"; trace "Multiple types detected, prioritizing Rust"; elif [[ " ${detected_types[*]} " =~ " js " ]]; then primary_type="js"; trace "Multiple types detected, prioritizing JavaScript"; elif [[ " ${detected_types[*]} " =~ " python " ]]; then primary_type="python"; trace "Multiple types detected, prioritizing Python"; elif [[ " ${detected_types[*]} " =~ " bash " ]]; then primary_type="bash"; trace "Multiple types detected, using Bash"; else error "Cannot determine primary project type from: ${detected_types[*]}"; return 1; fi; ;; esac; printf "%s\n" "$primary_type"; return 0; }
declare -ga PROJECT_TYPES=();

# From parts/semv_sync_parsers.sh
__parse_cargo_version() { local cargo_file="Cargo.toml"; local version; local ret=1; if [[ ! -f "$cargo_file" ]]; then error "Cargo.toml not found"; return 1; fi; version=$(awk '/^\[package\]/ { in_package = 1; next } /^\[/ { in_package = 0; next } in_package && /^version[[:space:]]*=[[:space:]]*/ { gsub(/^version[[:space:]]*=[[:space:]]*/, ""); gsub(/^["'"'"']/, ""); gsub(/["'"'"'].*$/, ""); print; exit }' "$cargo_file"); if [[ -n "$version" ]]; then printf "%s\n" "$version"; ret=0; else error "Failed to parse version from Cargo.toml"; fi; return "$ret"; }
__write_cargo_version() { local new_version="$1"; local cargo_file="Cargo.toml"; local backup_file="${cargo_file}.semv-backup"; local ret=1; if [[ -z "$new_version" ]]; then error "Version required"; return 1; fi; if [[ ! -f "$cargo_file" ]]; then error "Cargo.toml not found"; return 1; fi; if ! cp "$cargo_file" "$backup_file"; then error "Failed to create backup of Cargo.toml"; return 1; fi; awk -v new_ver="$new_version" '/^\[package\]/ { in_package = 1; print; next } /^\[/ { in_package = 0; print; next } in_package && /^version[[:space:]]*=[[:space:]]*/ { print "version = \"" new_ver "\""; next } { print }' "$backup_file" > "$cargo_file"; if [[ $? -eq 0 ]]; then trace "Updated Cargo.toml version to $new_version"; rm "$backup_file"; ret=0; else error "Failed to update Cargo.toml"; mv "$backup_file" "$cargo_file"; fi; return "$ret"; }
__parse_package_version() { local package_file="package.json"; local version; local ret=1; if [[ ! -f "$package_file" ]]; then error "package.json not found"; return 1; fi; version=$(awk -F'"' '/"version"[[:space:]]*:[[:space:]]*"/ { for (i = 1; i <= NF; i++) { if ($i ~ /version/) { print $(i+2); exit } } }' "$package_file"); if [[ -n "$version" ]]; then printf "%s\n" "$version"; ret=0; else error "Failed to parse version from package.json"; fi; return "$ret"; }
__write_package_version() { local new_version="$1"; local package_file="package.json"; local backup_file="${package_file}.semv-backup"; local ret=1; if [[ -z "$new_version" ]]; then error "Version required"; return 1; fi; if [[ ! -f "$package_file" ]]; then error "package.json not found"; return 1; fi; if ! cp "$package_file" "$backup_file"; then error "Failed to create backup of package.json"; return 1; fi; if sed -i.tmp 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "'$new_version'"/' "$package_file"; then trace "Updated package.json version to $new_version"; rm -f "${package_file}.tmp" "$backup_file"; ret=0; else error "Failed to update package.json"; mv "$backup_file" "$package_file"; fi; return "$ret"; }
__parse_pyproject_version() { local pyproject_file="pyproject.toml"; local version; local ret=1; if [[ ! -f "$pyproject_file" ]]; then error "pyproject.toml not found"; return 1; fi; version=$(awk '/^\[project\]/ { in_project = 1; next } /^\[/ { in_project = 0; next } in_project && /^version[[:space:]]*=[[:space:]]*/ { gsub(/^version[[:space:]]*=[[:space:]]*/, ""); gsub(/^["'"'"']/, ""); gsub(/["'"'"'].*$/, ""); print; exit }' "$pyproject_file"); if [[ -n "$version" ]]; then printf "%s\n" "$version"; ret=0; else error "Failed to parse version from pyproject.toml"; fi; return "$ret"; }
__write_pyproject_version() { local new_version="$1"; local pyproject_file="pyproject.toml"; local backup_file="${pyproject_file}.semv-backup"; local ret=1; if [[ -z "$new_version" ]]; then error "Version required"; return 1; fi; if [[ ! -f "$pyproject_file" ]]; then error "pyproject.toml not found"; return 1; fi; if ! cp "$pyproject_file" "$backup_file"; then error "Failed to create backup of pyproject.toml"; return 1; fi; awk -v new_ver="$new_version" '/^\[project\]/ { in_project = 1; print; next } /^\[/ { in_project = 0; print; next } in_project && /^version[[:space:]]*=[[:space:]]*/ { print "version = \"" new_ver "\""; next } { print }' "$backup_file" > "$pyproject_file"; if [[ $? -eq 0 ]]; then trace "Updated pyproject.toml version to $new_version"; rm "$backup_file"; ret=0; else error "Failed to update pyproject.toml"; mv "$backup_file" "$pyproject_file"; fi; return "$ret"; }
__parse_bash_version() { local -a script_files; local file; local version; local ret=1; mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null); for file in "${script_files[@]}"; do if [[ -f "$file" ]]; then version=$(grep "^# version:" "$file" 2>/dev/null | head -1 | sed 's/^# version:[[:space:]]*//' | tr -d ' '); if [[ -n "$version" ]]; then printf "%s\n" "$version"; ret=0; break; fi; fi; done; if [[ "$ret" -ne 0 ]]; then error "No bash script with version metadata found"; fi; return "$ret"; }
__write_bash_version() { local new_version="$1"; local -a script_files; local file; local backup_file; local ret=1; if [[ -z "$new_version" ]]; then error "Version required"; return 1; fi; mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null); for file in "${script_files[@]}"; do if [[ -f "$file" ]] && grep -q "^# version:" "$file" 2>/dev/null; then backup_file="${file}.semv-backup"; if ! cp "$file" "$backup_file"; then error "Failed to create backup of $file"; continue; fi; if sed -i.tmp "s/^# version:.*/# version: $new_version/" "$file"; then trace "Updated $file version to $new_version"; rm -f "${file}.tmp" "$backup_file"; ret=0; break; else error "Failed to update $file"; mv "$backup_file" "$file"; fi; fi; done; if [[ "$ret" -ne 0 ]]; then error "No bash script with version metadata found to update"; fi; return "$ret"; }
__parse_cursor_version() { local cursor_file=".build"; local version; local ret=1; if [[ -f "$cursor_file" ]]; then :; elif [[ -f "build/build.inf" ]]; then cursor_file="build/build.inf"; elif [[ -f "build.inf" ]]; then cursor_file="build.inf"; else trace "No build cursor file found"; return 1; fi; version=$(grep "^DEV_SEMVER=" "$cursor_file" 2>/dev/null | head -1 | cut -d'=' -f2); if [[ -z "$version" ]]; then version=$(grep "^DEV_VERS=" "$cursor_file" 2>/dev/null | head -1 | cut -d'=' -f2); fi; if [[ -n "$version" ]]; then printf "%s\n" "$version"; ret=0; else error "Failed to parse version from cursor file: $cursor_file"; fi; return "$ret"; }
__write_cursor_version() { local new_version="$1"; local cursor_file=".build"; local backup_file; local ret=1; if [[ -z "$new_version" ]]; then error "Version required"; return 1; fi; if [[ -f "$cursor_file" ]]; then :; elif [[ -f "build/build.inf" ]]; then cursor_file="build/build.inf"; elif [[ -f "build.inf" ]]; then cursor_file="build.inf"; else trace "Creating new build cursor file: $cursor_file"; if ! __print_build_info "$cursor_file"; then error "Failed to create build cursor file"; return 1; fi; ret=0; fi; if [[ "$ret" -ne 0 ]] && [[ -f "$cursor_file" ]]; then backup_file="${cursor_file}.semv-backup"; if ! cp "$cursor_file" "$backup_file"; then error "Failed to create backup of $cursor_file"; return 1; fi; sed -i.tmp -e "s/^DEV_SEMVER=.*/DEV_SEMVER=$new_version/" -e "s/^DEV_VERS=.*/DEV_VERS=$new_version/" "$cursor_file"; if [[ $? -eq 0 ]]; then trace "Updated $cursor_file version to $new_version"; rm -f "${cursor_file}.tmp" "$backup_file"; ret=0; else error "Failed to update $cursor_file"; mv "$backup_file" "$cursor_file"; fi; fi; return "$ret"; }

# From parts/semv_sync_commands.sh
do_sync() { local project_type="$1"; local -a detected_types; local -a all_versions; local highest_version; local ret=1; if ! is_repo; then error "Not in a git repository"; return 1; fi; info "Starting version synchronization..."; if ! _validate_project_structure; then return 1; fi; if [[ -n "$project_type" ]]; then detected_types=("$project_type"); info "Syncing specific project type: $project_type"; else mapfile -t detected_types < <(_detect_project_type); if [[ "${#detected_types[@]}" -eq 0 ]]; then error "No supported project types detected"; return 1; fi; info "Detected project types: ${detected_types[*]}"; fi; if ! _gather_all_versions all_versions "${detected_types[@]}"; then error "Failed to gather version information"; return 1; fi; highest_version=$(_find_highest_version "${all_versions[@]}"); if [[ -z "$highest_version" ]]; then error "No valid versions found"; return 1; fi; info "Highest version found: $highest_version"; if _sync_all_sources "$highest_version" "${detected_types[@]}"; then okay "Version synchronization completed successfully"; info "All sources synced to: $highest_version"; _update_cursor_sync_info "$highest_version" "${detected_types[0]}"; ret=0; else error "Failed to synchronize all sources"; fi; return "$ret"; }
do_validate() { local -a detected_types; local -a all_versions; local -a unique_versions; local ret=1; if ! is_repo; then error "Not in a git repository"; return 1; fi; info "Validating version synchronization..."; mapfile -t detected_types < <(_detect_project_type); if [[ "${#detected_types[@]}" -eq 0 ]]; then warn "No supported project types detected"; return 0; fi; if ! _gather_all_versions all_versions "${detected_types[@]}"; then error "Failed to gather version information"; return 1; fi; mapfile -t unique_versions < <(printf "%s\n" "${all_versions[@]}" | sort -u); if [[ "${#unique_versions[@]}" -eq 1 ]]; then okay "All sources are in sync: ${unique_versions[0]}"; ret=0; else warn "Version drift detected:"; _show_version_drift "${detected_types[@]}"; ret=1; fi; return "$ret"; }
do_drift() { local -a detected_types; if ! is_repo; then error "Not in a git repository"; return 1; fi; info "Checking for version drift..."; mapfile -t detected_types < <(_detect_project_type); if [[ "${#detected_types[@]}" -eq 0 ]]; then warn "No supported project types detected"; return 0; fi; _show_version_drift "${detected_types[@]}"; return 0; }
_gather_all_versions() { local -n versions_ref="$1"; shift; local project_type; local version; local git_version; local cursor_version; versions_ref=(); git_version=$(do_latest_tag 2>/dev/null); if [[ -n "$git_version" ]] && is_valid_semver "$git_version"; then versions_ref+=("$git_version"); trace "Git version: $git_version"; fi; cursor_version=$(__parse_cursor_version 2>/dev/null); if [[ -n "$cursor_version" ]] && is_valid_semver "$cursor_version"; then versions_ref+=("$cursor_version"); trace "Cursor version: $cursor_version"; fi; for project_type in "$@"; do version=$(_get_project_version "$project_type" 2>/dev/null); if [[ -n "$version" ]] && is_valid_semver "$version"; then if [[ ! "$version" =~ ^v ]]; then version="v$version"; fi; versions_ref+=("$version"); trace "$project_type version: $version"; else warn "Failed to get valid version from $project_type source"; fi; done; if [[ "${#versions_ref[@]}" -eq 0 ]]; then return 1; fi; return 0; }
_find_highest_version() { local -a versions=("$@"); local highest=""; local version; if [[ "${#versions[@]}" -eq 0 ]]; then return 1; fi; highest="${versions[0]}"; for version in "${versions[@]:1}"; do if do_is_greater "$version" "$highest"; then highest="$version"; fi; done; printf "%s\n" "$highest"; return 0; }
_sync_all_sources() { local target_version="$1"; shift; local project_type; local clean_version; local ret=0; clean_version="${target_version#v}"; clean_version="${clean_version%%-*}"; trace "Syncing to target: $target_version (clean: $clean_version)"; for project_type in "$@"; do case "$project_type" in rust) if ! __write_cargo_version "$clean_version"; then error "Failed to update Cargo.toml"; ret=1; fi ;; js) if ! __write_package_version "$clean_version"; then error "Failed to update package.json"; ret=1; fi ;; python) if ! __write_pyproject_version "$clean_version"; then error "Failed to update pyproject.toml"; ret=1; fi ;; bash) if ! __write_bash_version "$clean_version"; then error "Failed to update bash script version"; ret=1; fi ;; *) warn "Unknown project type: $project_type"; ;; esac; done; if ! __write_cursor_version "$target_version"; then warn "Failed to update build cursor"; fi; return "$ret"; }
_show_version_drift() { local project_type; local version; local git_version; local cursor_version; info "Version source comparison:"; git_version=$(do_latest_tag 2>/dev/null); if [[ -n "$git_version" ]]; then info "  Git tags: $git_version"; else warn "  Git tags: none found"; fi; cursor_version=$(__parse_cursor_version 2>/dev/null); if [[ -n "$cursor_version" ]]; then info "  Build cursor: $cursor_version"; else warn "  Build cursor: none found"; fi; for project_type in "$@"; do version=$(_get_project_version "$project_type" 2>/dev/null); if [[ -n "$version" ]]; then info "  $project_type: $version"; else warn "  $project_type: failed to parse"; fi; done; }
_update_cursor_sync_info() { local synced_version="$1"; local primary_source="$2"; local cursor_file=".build"; if [[ -f "build/build.inf" ]]; then cursor_file="build/build.inf"; elif [[ -f "build.inf" ]]; then cursor_file="build.inf"; fi; if [[ -f "$cursor_file" ]]; then sed -i.tmp -e "s/^SYNC_SOURCE=.*/SYNC_SOURCE=$primary_source/" -e "s/^SYNC_VERSION=.*/SYNC_VERSION=$synced_version/" -e "s/^SYNC_DATE=.*/SYNC_DATE=$(date -Iseconds)/" "$cursor_file"; if [[ $? -eq 0 ]]; then rm -f "${cursor_file}.tmp"; trace "Updated cursor sync info: $primary_source -> $synced_version"; else warn "Failed to update cursor sync info"; mv "${cursor_file}.tmp" "$cursor_file" 2>/dev/null; fi; fi; return 0; }
do_sync_rust() { if ! is_rust_project; then error "Not a Rust project (Cargo.toml not found)"; return 1; fi; do_sync "rust"; }
do_sync_js() { if ! is_js_project; then error "Not a JavaScript project (package.json not found)"; return 1; fi; do_sync "js"; }
do_sync_python() { if ! is_python_project; then error "Not a Python project (pyproject.toml not found)"; return 1; fi; do_sync "python"; }
do_sync_bash() { if ! is_bash_project; then error "Not a Bash project (no script with version metadata found)"; return 1; fi; do_sync "bash"; }

# From parts/semv_sync_integration.sh
_show_last_sync_info() { local cursor_file=".build"; local sync_source; local sync_version; local sync_date; if [[ -f "build/build.inf" ]]; then cursor_file="build/build.inf"; elif [[ -f "build.inf" ]]; then cursor_file="build.inf"; fi; if [[ -f "$cursor_file" ]]; then sync_source=$(grep "^SYNC_SOURCE=" "$cursor_file" 2>/dev/null | cut -d'=' -f2); sync_version=$(grep "^SYNC_VERSION=" "$cursor_file" 2>/dev/null | cut -d'=' -f2); sync_date=$(grep "^SYNC_DATE=" "$cursor_file" 2>/dev/null | cut -d'=' -f2); if [[ -n "$sync_source" ]] && [[ -n "$sync_version" ]]; then info "Last sync: $sync_source -> $sync_version"; if [[ -n "$sync_date" ]]; then info "Sync date: $sync_date"; fi; else trace "No previous sync information found"; fi; fi; }
do_pre_commit() { local -a detected_types; local ret=0; if ! is_repo; then error "Not in a git repository"; return 1; fi; info "Running pre-commit validation..."; mapfile -t detected_types < <(_detect_project_type 2>/dev/null); if [[ "${#detected_types[@]}" -eq 0 ]]; then okay "No sync sources - pre-commit validation passed"; return 0; fi; info "Checking sync status for: ${detected_types[*]}"; if do_validate >/dev/null 2>&1; then okay "All sources are in sync"; else error "Version drift detected - commit blocked"; warn "Run 'semv sync' to synchronize versions before committing"; ret=1; fi; if _check_version_files_staged "${detected_types[@]}"; then warn "Version files have unstaged changes"; if __confirm "Stage version files automatically"; then _stage_version_files "${detected_types[@]}"; okay "Version files staged"; else warn "Version files remain unstaged"; fi; fi; return "$ret"; }
_check_version_files_staged() { local project_type; local file_changed=0; for project_type in "$@"; do case "$project_type" in rust) if git diff --name-only | grep -q "^Cargo.toml$"; then file_changed=1; fi ;; js) if git diff --name-only | grep -q "^package.json$"; then file_changed=1; fi ;; python) if git diff --name-only | grep -q "^pyproject.toml$"; then file_changed=1; fi ;; bash) if git diff --name-only | grep -q "\.sh$"; then file_changed=1; fi ;; esac; done; return "$file_changed"; }
_stage_version_files() { local project_type; for project_type in "$@"; do case "$project_type" in rust) if [[ -f "Cargo.toml" ]]; then git add Cargo.toml; trace "Staged Cargo.toml"; fi ;; js) if [[ -f "package.json" ]]; then git add package.json; trace "Staged package.json"; fi ;; python) if [[ -f "pyproject.toml" ]]; then git add pyproject.toml; trace "Staged pyproject.toml"; fi ;; bash) local -a script_files; mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null); local file; for file in "${script_files[@]}"; do if [[ -f "$file" ]] && grep -q "^# version:" "$file" 2>/dev/null; then git add "$file"; trace "Staged $file"; fi; done ;; esac; done; local cursor_file; for cursor_file in ".build" "build.inf" "build/build.inf"; do if [[ -f "$cursor_file" ]]; then git add "$cursor_file"; trace "Staged $cursor_file"; break; fi; done; }
do_release() { local ret=1; if ! is_repo; then error "Not in a git repository"; return 1; fi; info "Starting full release workflow..."; if ! do_pre_commit; then error "Pre-release validation failed"; return 1; fi; if do_bump_with_sync; then okay "Release completed successfully"; do_info_with_sync; ret=0; else error "Release failed during bump"; fi; return "$ret"; }
do_build_file_with_sync() { local filename="${1:-build.inf}"; if do_build_file "$filename"; then local -a detected_types; mapfile -t detected_types < <(_detect_project_type 2>/dev/null); if [[ "${#detected_types[@]}" -gt 0 ]]; then _update_cursor_sync_info "$(do_latest_tag)" "${detected_types[0]}"; fi; return 0; else return 1; fi; }

#-------------------------------------------------------------------------------
# Dispatch & Main
#-------------------------------------------------------------------------------

dispatch() {
    local cmd="$1";
    local arg="$2";
    local arg2="$3";
    local ret=0;
    local func_name="";
    
    shift; # Remove command from args
    
    case "$cmd" in
        # Version Operations
        ""|latest|tag)     func_name="do_latest_semver";;
        next|dry)          func_name="do_next_semver";;
        bump)              func_name="do_bump";;
        
        # Project Analysis  
        info)              func_name="do_info";;
        pend|pending)      func_name="do_pending";;
        chg|changes)       func_name="do_change_count";;
        since|last)        func_name="do_last";;
        st|status)         func_name="__git_status_count";;
        
        # Build Operations
        file)              func_name="do_build_file";;
        bc|build-count)    func_name="do_build_count";;
        bcr|remote-build)  func_name="do_remote_build_count";;
        
        # Repository Management
        new|mark1)         func_name="do_mark_1";;
        can)               func_name="do_can_semver";;
        fetch)             func_name="do_fetch_tags";;
        tags)              func_name="do_tags";;
        
        # Version Validation
        test)              func_name="do_test_semver";;
        comp|compare)      func_name="do_compare_versions";;
        
        # Sync Commands
        sync)              func_name="do_sync";;
        validate|check)    func_name="do_validate";;
        drift)             func_name="do_drift";;
        sync-rust)         func_name="do_sync_rust";;
        sync-js)           func_name="do_sync_js";;
        sync-python)       func_name="do_sync_python";;
        sync-bash)         func_name="do_sync_bash";;

        # Workflow Commands
        release)           func_name="do_release";;
        pre-commit)        func_name="do_pre_commit";;

        # Lifecycle Commands
        install)           func_name="do_install";;
        uninstall)         func_name="do_uninstall";;
        reset)             func_name="do_reset";;
        
        # Development Commands
        inspect)           func_name="do_inspect";;
        lbl|labels)        func_name="do_label_help";;
        
        # Auto mode (for external tools)
        auto)              func_name="do_auto";;
        
        # Help
        help|\?)           func_name="usage";;
        
        *)
            if [[ -n "$cmd" ]]; then
                error "Invalid command: $cmd";
                usage;
                ret=1;
            else
                # Default behavior - show current version
                func_name="do_latest_semver";
            fi
            ;;
    esac
    
    # Execute the function if one was mapped
    if [[ -n "$func_name" ]]; then
        if function_exists "$func_name"; then
            trace "Dispatching: $cmd -> $func_name";
            "$func_name" "$arg" "$arg2" "$@";
            ret=$?;
        else
            error "Function $func_name not implemented yet";
            ret=1;
        fi
    fi
    
    return "$ret";
}

usage() {
    local help_text;
    
    printf -v help_text "%s" "
${bld}semv${x} - Semantic Version Manager

${bld}USAGE:${x}
    semv [command] [args] [flags]

${bld}VERSION OPERATIONS:${x}
    ${green}semv${x}              Show current version (default)
    ${green}next${x}              Calculate next version (dry run) 
    ${green}bump${x}              Create and push new version tag
    ${green}tag${x}               Show latest semantic version tag

${bld}PROJECT ANALYSIS:${x}
    ${green}info${x}              Show repository and version status
    ${green}pend${x}              Show pending changes since last tag
    ${green}since${x}             Time since last commit
    ${green}status${x}            Show working directory status

${bld}BUILD OPERATIONS:${x}
    ${green}file${x}              Generate build info file
    ${green}bc${x}                Show current build count

${bld}REPOSITORY MANAGEMENT:${x}
    ${green}new${x}               Initialize repo with v0.0.1
    ${green}can${x}               Check if repo can use semver
    ${green}fetch${x}             Fetch remote tags

${bld}SYNC & WORKFLOW:${x}
    ${green}sync${x}              Synchronize all version sources
    ${green}validate${x}          Check for version drift
    ${green}release${x}           Run pre-commit and bump workflow
    ${green}pre-commit${x}        Run pre-commit validation hook

${bld}FLAGS:${x}
    ${yellow}-d${x}                Enable debug messages
    ${yellow}-t${x}                Enable trace messages  
    ${yellow}-q${x}                Quiet mode (errors only)
    ${yellow}-f${x}                Force operations
    ${yellow}-y${x}                Auto-answer yes to prompts
    ${yellow}-D${x}                Master dev flag (enables -d, -t)

${bld}COMMIT LABELS:${x}
    ${orange}brk:${x}              Breaking changes → Major bump
    ${orange}feat:${x}             New features → Minor bump
    ${orange}fix:${x}              Bug fixes → Patch bump
    ${orange}dev:${x}              Development notes → Dev build

${bld}EXAMPLES:${x}
    semv                  # Show current version
    semv bump             # Bump and tag new version
    semv info             # Show project status
    semv -d pend          # Debug mode, show pending changes
";

    printf "%s\n" "$help_text" >&2;
    return 0;
}

main() {
    local orig_args=("$@");
    local -a filtered_args;
    local ret=0;
    
    # Parse options first
    if ! options "${orig_args[@]}"; then
        error "Failed to parse options";
        return 1;
    fi
    
    # Filter out flags to get commands/args
    mapfile -t filtered_args < <(_filter_args "${orig_args[@]}");
    
    # Basic validation
    if ! command_exists git; then
        fatal "Git is required but not found";
    fi
    
    # Dispatch to appropriate command
    dispatch "${filtered_args[@]}";
    ret=$?;
    
    return "$ret";
}

#===============================================================================
#=====================================!code=====================================
#===============================================================================

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@";
fi
