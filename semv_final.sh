#!/usr/bin/env bash
#
# SEMV - Semantic Version Manager  
# semv-revision: 2.0.0-dev_1
# semv-phase: Final Assembly
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

# Ensure XDG+ directories exist if we're in install mode
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

# Core colors
readonly red=$'\x1B[38;5;197m';      
readonly green=$'\x1B[32m';          
readonly blue=$'\x1B[36m';           
readonly orange=$'\x1B[38;5;214m';   
readonly yellow=$'\x1B[33m';         
readonly purple=$'\x1B[38;5;213m';   
readonly grey=$'\x1B[38;5;244m';     

# Extended colors
readonly blue2=$'\x1B[38;5;39m';
readonly cyan=$'\x1B[38;5;14m';
readonly white=$'\x1B[38;5;248m';
readonly white2=$'\x1B[38;5;15m';
readonly grey2=$'\x1B[38;5;240m';

# Control sequences
readonly revc=$'\x1B[7m';            
readonly bld=$'\x1B[1m';             
readonly x=$'\x1B[0m';               
readonly eol=$'\x1B[K';              

# Status indicators
readonly pass=$'\u2713';             
readonly fail=$'\u2715';             
readonly delta=$'\u25B3';            
readonly star=$'\u2605';             

# Progress and activity  
readonly lambda=$'\u03BB';           
readonly idots=$'\u2026';            
readonly bolt=$'\u21AF';             
readonly spark=$'\u27E1';            

# Utility characters
readonly tab=$'\t';
readonly nl=$'\n';
readonly sp=' ';

# Pre-composed colored glyphs for common patterns
readonly fail_red="${red}${fail}${x}";      
readonly pass_green="${green}${pass}${x}";  
readonly warn_orange="${orange}${delta}${x}"; 
readonly info_blue="${blue}${spark}${x}";   

# Maintain compatibility with original semv variable names
readonly inv="$revc";                

#-------------------------------------------------------------------------------
# Printers & Output
#-------------------------------------------------------------------------------

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

#-------------------------------------------------------------------------------
# Options & Flag Parsing
#-------------------------------------------------------------------------------

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

is_repo() {
    git rev-parse --is-inside-work-tree > /dev/null 2>&1;
}

is_main() {
    local branch;
    local ret=1;
    
    branch=$(this_branch);
    if [[ -n "$branch" ]] && [[ "$branch" == "main" || "$branch" == "master" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

has_commits() {
    local ret=1;
    
    if is_repo && git rev-parse HEAD > /dev/null 2>&1; then
        ret=0;
    fi
    
    return "$ret";
}

has_semver() {
    git tag --list | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+$';
}

is_not_staged() {
    git diff --exit-code > /dev/null 2>&1;
}

is_dev() {
    [[ "$opt_dev" -eq 0 ]] || [[ "${DEV_MODE:-}" == "1" ]];
}

is_quiet() {
    [[ "$opt_quiet" -eq 0 ]] || [[ "${QUIET_MODE:-}" == "1" ]];
}

is_force() {
    [[ "$opt_force" -eq 0 ]];
}

command_exists() {
    local cmd="$1";
    type "$cmd" &> /dev/null;
}

function_exists() {
    local func="$1";
    [[ -n "$func" ]] && declare -F "$func" >/dev/null;
}

is_empty() {
    local var="$1";
    [[ -z "$var" ]];
}

is_valid_semver() {
    local version="$1";
    [[ "$version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]];
}

is_file() {
    local path="$1";
    [[ -f "$path" && -r "$path" ]];
}

is_dir() {
    local path="$1";
    [[ -d "$path" ]];
}

is_writable() {
    local path="$1";
    [[ -w "$path" ]];
}

#-------------------------------------------------------------------------------
# Git Operations
#-------------------------------------------------------------------------------

this_branch() {
    git branch --show-current;
}

this_user() {
    git config user.name | tr -d ' ';
}

this_project() {
    basename "$(git rev-parse --show-toplevel)";
}

which_main() {
    local ret=1;
    
    if has_commits; then
        git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@';
        ret=0;
    fi
    
    return "$ret";
}

last_commit() {
    local ret=1;
    
    if has_commits; then
        if git rev-parse HEAD >/dev/null 2>&1; then
            git show -s --format=%ct HEAD;
            ret=0;
        fi
    fi
    
    if [[ "$ret" -eq 1 ]]; then
        echo "0";
    fi
    
    return "$ret";
}

since_last() {
    local tag="$1";
    local label="$2";
    local count;
    local ret=1;

    if is_repo; then
        count=$(git log --pretty=format:"%s" "${tag}"..HEAD | grep -cE "^${label}:");
        echo "$count";
        trace "[$count] [$label] changes since [$tag]";
        ret=0;
    else
        error "Error. current dir not a git repo.";
    fi
    
    return "$ret";
}

__git_list_tags() {
    git show-ref --tags | cut -d '/' -f 3-;
}

__git_latest_tag() {
    local latest;
    local ret=1;
    
    if is_repo; then
        latest=$(git tag | sort -V | tail -n1);
        if [[ -n "$latest" ]]; then
            echo "$latest";
            ret=0;
        fi
    fi
    
    return "$ret";
}

__git_latest_semver() {
    local latest;
    local ret=1;
    
    if has_semver; then
        latest=$(git tag --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1);
        if [[ -n "$latest" ]]; then
            echo "$latest";
            ret=0;
        fi
    fi
    
    return "$ret";
}

__git_tag_create() {
    local tag="$1";
    local msg="$2";
    local ret=1;
    
    if [[ -n "$tag" ]] && [[ -n "$msg" ]]; then
        git tag -a "$tag" -m "$msg";
        ret=$?;
    fi
    
    return "$ret";
}

__git_push_tags() {
    local force_flag="";
    local ret=1;
    
    if [[ "$1" == "force" ]]; then
        force_flag="--force";
    fi
    
    git push --tags $force_flag;
    ret=$?;
    
    return "$ret";
}

__git_build_count() {
    local count;
    
    count=$(git rev-list HEAD --count);
    count=$((count + SEMV_MIN_BUILD));
    echo "$count";
    return 0;
}

__git_remote_build_count() {
    local count;
    
    count=$(git rev-list origin/main --count 2>/dev/null || echo 0);
    count=$((count + SEMV_MIN_BUILD));
    echo "$count";
    return 0;
}

__git_status_count() {
    local count;
    
    count=$(git status --porcelain | wc -l | awk '{print $1}');
    echo "$count";
    return 0;
}

__git_fetch_tags() {
    local before_fetch;
    local after_fetch;
    local output;
    local ret;
    
    before_fetch=$(git tag);
    output=$(git fetch --tags 2>&1);
    ret=$?;
    after_fetch=$(git tag);
    
    if [[ "$before_fetch" != "$after_fetch" ]]; then
        okay "New tag changes found.";
    else
        info "No new tags.";
    fi
    
    return "$ret";
}

#-------------------------------------------------------------------------------
# Version Logic
#-------------------------------------------------------------------------------

split_vers() {
    local vers_str="$1";
    local ret=1;
    
    if [[ -z "$vers_str" ]]; then
        return 1;
    fi
    
    if [[ $vers_str =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; then
        major=${BASH_REMATCH[1]};
        minor=${BASH_REMATCH[2]};
        patch=${BASH_REMATCH[3]};
        extra=${BASH_REMATCH[4]};
        printf "%s %s %s %s\n" "$major" "$minor" "$patch" "$extra";
        ret=0;
    fi
    
    return "$ret";
}

do_compare_versions() {
    local v1="$1";
    local op="$2"; 
    local v2="$3";
    local result;
    local ret=1;
    
    if [[ -z "$v1" ]] || [[ -z "$v2" ]] || [[ -z "$op" ]]; then
        error "Usage: do_compare_versions <version1> <operator> <version2>";
        return 1;
    fi
    
    # Easy case: versions are identical
    if [[ "$v1" == "$v2" ]]; then
        case "$op" in
            '='|'=='|'>='|'<=') 
                printf "true\n";
                ret=0;
                ;;
            *) 
                printf "false\n";
                ret=1;
                ;;
        esac
        return "$ret";
    fi

    # Split versions into arrays using '.' as delimiter
    local OLD_IFS="$IFS";
    IFS='.';
    local -a ver1=($v1) ver2=($v2);
    IFS="$OLD_IFS";

    # Remove 'v' prefix if present
    ver1[0]=${ver1[0]#v};
    ver2[0]=${ver2[0]#v};

    # Find the longest version array to iterate through
    local i;
    local len1=${#ver1[@]};
    local len2=${#ver2[@]};
    local max_len=$(( len1 > len2 ? len1 : len2 ));

    # Compare each component numerically
    for ((i = 0; i < max_len; i++)); do
        # Pad missing components with 0
        local c1=${ver1[i]:-0};
        local c2=${ver2[i]:-0};
        
        # Remove any non-numeric suffixes for comparison
        c1=${c1%%-*};
        c2=${c2%%-*};

        if (( c1 > c2 )); then
            case "$op" in 
                '>'|'>='|'!=') 
                    printf "true\n";
                    ret=0;
                    ;;
                *) 
                    printf "false\n";
                    ret=1;
                    ;;
            esac
            return "$ret";
        fi
        
        if (( c1 < c2 )); then
            case "$op" in 
                '<'|'<='|'!=') 
                    printf "true\n";
                    ret=0;
                    ;;
                *) 
                    printf "false\n";
                    ret=1;
                    ;;
            esac
            return "$ret";
        fi
    done

    # If we get here, they are equal component-by-component
    case "$op" in 
        '='|'=='|'>='|'<=') 
            printf "true\n";
            ret=0;
            ;;
        *) 
            printf "false\n";
            ret=1;
            ;;
    esac
    
    return "$ret";
}

do_is_greater() {
    local version_b="$1";
    local version_a="$2";
    local result;
    local ret=1;
    
    if [[ -z "$version_a" ]] || [[ -z "$version_b" ]]; then
        error "Invalid comparison - missing version";
        return 1;
    fi
    
    trace "$version_b > $version_a ?";

    # Use comparison function
    result=$(do_compare_versions "$version_b" ">" "$version_a");
    if [[ "$result" == "true" ]]; then
        trace "$version_b > $version_a ✓";
        ret=0;
    else
        trace "$version_b <= $version_a ✗";
        ret=1;
    fi
    
    return "$ret";
}

do_test_semver() {
    local version="$1";
    local parts;
    local ret=1;
    
    if [[ -z "$version" ]]; then
        error "Usage: do_test_semver <version>";
        return 1;
    fi
    
    info "Testing version format: $version";
    
    parts=$(split_vers "$version");
    ret=$?;
    
    if [[ "$ret" -eq 0 ]]; then
        local -a components=($parts);
        okay "Valid semantic version format";
        info "Major: ${components[0]}";
        info "Minor: ${components[1]}";  
        info "Patch: ${components[2]}";
        if [[ -n "${components[3]}" ]]; then
            info "Extra: ${components[3]}";
        fi
        printf "%s\n" "$parts";
    else
        error "Invalid semantic version format";
        error "Expected format: v1.2.3 or v1.2.3-suffix";
    fi
    
    return "$ret";
}

#-------------------------------------------------------------------------------
# Semver Core Logic
#-------------------------------------------------------------------------------

do_latest_tag() {
    local latest;
    local ret=1;
    
    if is_repo; then
        latest=$(__git_latest_tag);
        if [[ -n "$latest" ]]; then
            printf "%s\n" "$latest";
            ret=0;
        fi
    fi
    
    return "$ret";
}

do_latest_semver() {
    local latest;
    local ret=1;
    
    if has_semver; then
        latest=$(__git_latest_semver);
        if [[ -n "$latest" ]]; then
            printf "%s\n" "$latest";
            ret=0;
        else
            error "No semver tags found";
        fi
    else
        error "No semver tags found";
    fi
    
    return "$ret";
}

do_change_count() {
    local tag="${1:-$(do_latest_tag)}";
    local break_count;
    local feat_count;
    local fix_count;
    local dev_count;
    local ret=1;
    
    if [[ -z "$tag" ]]; then
        error "No tag specified and no tags found";
        return 1;
    fi
    
    # Initialize bump flags
    b_major=0;
    b_minor=0;
    b_patch=0;
    
    # Count commits by type since tag
    break_count=$(since_last "$tag" "$SEMV_MAJ_LABEL");
    feat_count=$(since_last "$tag" "$SEMV_FEAT_LABEL");
    fix_count=$(since_last "$tag" "$SEMV_FIX_LABEL");
    dev_count=$(since_last "$tag" "$SEMV_DEV_LABEL");
    build_s=$(__git_build_count);
    note_s="$dev_count";
    
    trace "Changes since $tag: brk=$break_count feat=$feat_count fix=$fix_count dev=$dev_count";
    
    # Determine version bump based on commit types
    if [[ "$break_count" -ne 0 ]]; then
        trace "Found breaking changes - major bump";
        b_major=1;
        b_minor=0;
        b_patch=0;
        ret=0;
    elif [[ "$feat_count" -ne 0 ]]; then
        trace "Found new features - minor bump";
        b_minor=1;
        b_patch=0;
        ret=0;
    elif [[ "$fix_count" -ne 0 ]]; then
        trace "Found bug fixes - patch bump";
        b_patch=1;
        ret=0;
    elif [[ "$dev_count" -ne 0 ]]; then
        trace "Found dev notes - no version bump";
        ret=0;
    fi
    
    return "$ret";
}

do_next_semver() {
    local force="${1:-1}";
    local tag;
    local parts;
    local major;
    local minor; 
    local patch;
    local extra;
    local new_version;
    local tail_suffix="";
    local ret=1;
    
    # Get latest tag as base
    tag=$(do_latest_tag);
    if [[ -z "$tag" ]]; then
        error "No tags found to bump from";
        return 1;
    fi
    
    # Parse current version
    parts=$(split_vers "$tag");
    if [[ $? -ne 0 ]]; then
        error "Invalid version format: $tag";
        return 1;
    fi
    
    # Extract version components
    local -a components=($parts);
    major="${components[0]}";
    minor="${components[1]}";
    patch="${components[2]}";
    extra="${components[3]}";
    
    # Analyze changes to determine bump
    if ! do_change_count "$tag"; then
        if [[ "$opt_dev_note" -eq 0 ]]; then
            error "No changes since last tag ($tag)";
            return 1;
        fi
    fi
    
    # Apply version bumps
    major=$((major + b_major));
    minor=$((minor + b_minor));
    patch=$((patch + b_patch));
    
    # Reset lower components when higher ones bump
    if [[ "$b_major" -eq 1 ]]; then
        minor=0;
        patch=0;
    elif [[ "$b_minor" -eq 1 ]]; then
        patch=0;
    fi
    
    # Build new version string
    new_version="v${major}.${minor}.${patch}";
    
    # Add development suffix if enabled
    if [[ "$opt_dev_note" -eq 0 ]]; then
        if [[ "$note_s" -ne 0 ]]; then
            trace "Dev notes found - adding dev suffix";
            tail_suffix="-dev_${note_s}";
        else
            trace "Clean build - adding build suffix";
            tail_suffix="-build_${build_s}";
        fi
        new_version="${new_version}${tail_suffix}";
    fi
    
    trace "Version calculation: $tag -> $new_version";
    
    # Confirmation for releases with dev notes
    if [[ "$force" -ne 0 ]] && [[ "$note_s" -ne 0 ]] && [[ "$opt_dev_note" -eq 1 ]]; then
        warn "There are [$note_s] dev notes and --dev flag is disabled";
        info "Current: $tag";
        info "Next: $new_version";
        warn "You should only bump versions if dev notes are resolved";
        
        if ! __confirm "Continue with version bump"; then
            error "Version bump cancelled";
            return 1;
        fi
    fi
    
    printf "%s\n" "$new_version";
    ret=0;
    return "$ret";
}

__print_build_info() {
    local dest="$1";
    local version;
    local build;
    local branch;
    local semver;
    local ret=1;
    
    if [[ -z "$dest" ]]; then
        return 1;
    fi
    
    # Gather build information
    version=$(do_latest_tag);
    build=$(__git_build_count);
    branch=$(this_branch);
    semver=$(do_next_semver 0 2>/dev/null || echo "$version");
    
    # Write build information
    cat > "$dest" << EOF
DEV_VERS=${version}
DEV_BUILD=${build}
DEV_BRANCH=${branch}
DEV_DATE=$(date +%D)
DEV_SEMVER=${semver}
SYNC_SOURCE=
SYNC_VERSION=
SYNC_DATE=
EOF

    if [[ -f "$dest" ]] && [[ -s "$dest" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

do_build_file() {
    local filename="${1:-build.inf}";
    local dest;
    local ret=1;
    
    # Skip if cursor disabled
    if [[ "$opt_no_cursor" -eq 0 ]]; then
        trace "Build cursor disabled - skipping file generation";
        return 0;
    fi
    
    # Determine destination path
    if [[ "$opt_build_dir" -eq 0 ]]; then
        if [[ ! -d "./build" ]]; then
            mkdir -p "./build";
        fi
        dest="./build/${filename}";
    else
        dest="./${filename}";
    fi
    
    # Generate build file
    if __print_build_info "$dest"; then
        okay "Build file generated: $dest";
        if [[ "$opt_trace" -eq 0 ]]; then
            cat "$dest";
        fi
        ret=0;
    else
        error "Failed to generate build file";
    fi
    
    return "$ret";
}

do_can_semver() {
    local last;
    local branch;
    
    if is_repo; then
        last=$(do_latest_tag);
        branch=$(this_branch);
        
        if [[ -z "$last" ]]; then
            okay "Can use semver here. Repository found.";
            info "Use 'semv new' to set initial v0.0.1 version";
        else
            info "Semver found: $last";
            info "Use 'semv bump' to update version";
        fi
        
        info "Current branch: $branch";
    else
        error "Not in a git repository";
    fi
    
    return 0;
}

do_mark_1() {
    local last;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    if ! has_semver; then
        if is_main; then
            warn "Mark 1 will setup initial semver at v0.0.1";
            
            # Ensure we have something to commit
            if [[ ! -f "README.md" ]]; then
                touch README.md;
            fi
            
            # Add and commit
            git add README.md;
            git commit -m "auto: Update README for repository setup :robot:";
            
            # Create initial tag
            if __git_tag_create "v0.0.1" "auto: Initial semver tag"; then
                okay "Created initial tag: v0.0.1";
                
                if __confirm "Push initial tag (v0.0.1) to origin"; then
                    git push origin v0.0.1;
                    git push origin main;
                    okay "Pushed to origin";
                fi
                ret=0;
            else
                error "Failed to create initial tag";
            fi
        else
            warn "Not on main branch - cannot initialize semver";
        fi
    else
        last=$(do_latest_tag);
        warn "Repository already has semver: $last";
        warn "Cannot initialize to v0.0.1";
    fi
    
    return "$ret";
}

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

do_build_count() {
    __git_build_count;
}

do_remote_build_count() {
    __git_remote_build_count;
}

#-------------------------------------------------------------------------------
# Installation Functions
#-------------------------------------------------------------------------------

do_install() {
    local ret=1;
    local semv_bin="${XDG_BIN:-$HOME/.local/bin}/semv";
    local semv_lib="${XDG_LIB:-$HOME/.local/lib}/fx/semv";
    
    info "Installing SEMV to BashFX system...";
    
    # Ensure XDG+ directories exist
    if ! _ensure_xdg_paths; then
        error "Failed to create XDG+ directories";
        return 1;
    fi
    
    # Create semv lib directory
    if ! mkdir -p "$semv_lib"; then
        error "Failed to create semv library directory: $semv_lib";
        return 1;
    fi
    
    # Copy script to lib location
    if ! cp "$SEMV_PATH" "$semv_lib/semv.sh"; then
        error "Failed to copy semv script to library";
        return 1;
    fi
    
    # Create symlink in bin
    if ! ln -sf "$semv_lib/semv.sh" "$semv_bin"; then
        error "Failed to create binary symlink";
        return 1;
    fi
    
    # Make executable
    if ! chmod +x "$semv_lib/semv.sh"; then
        error "Failed to make script executable";
        return 1;
    fi
    
    # Create initial configuration
    if ! __create_default_config; then
        warn "Failed to create default configuration";
    fi
    
    # Create RC file for session state
    if ! __create_rc_file; then
        warn "Failed to create RC file";
    fi
    
    okay "SEMV installed successfully";
    info "Binary: $semv_bin";
    info "Library: $semv_lib";
    info "Configuration: $SEMV_CONFIG";
    
    ret=0;
    return "$ret";
}

do_uninstall() {
    local ret=1;
    local semv_bin="${XDG_BIN:-$HOME/.local/bin}/semv";
    local semv_lib="${XDG_LIB:-$HOME/.local/lib}/fx/semv";
    
    info "Uninstalling SEMV from BashFX system...";
    
    # Remove symlink
    if [[ -L "$semv_bin" ]]; then
        if rm "$semv_bin"; then
            okay "Removed binary symlink: $semv_bin";
        else
            error "Failed to remove binary symlink";
            return 1;
        fi
    fi
    
    # Remove library directory
    if [[ -d "$semv_lib" ]]; then
        if rm -rf "$semv_lib"; then
            okay "Removed library directory: $semv_lib";
        else
            error "Failed to remove library directory";
            return 1;
        fi
    fi
    
    # Ask about configuration removal
    if [[ -d "$SEMV_CONFIG" ]]; then
        if __confirm "Remove configuration directory ($SEMV_CONFIG)"; then
            if rm -rf "$SEMV_CONFIG"; then
                okay "Removed configuration directory";
            else
                warn "Failed to remove configuration directory";
            fi
        else
            info "Keeping configuration directory";
        fi
    fi
    
    # Ask about data removal
    if [[ -d "$SEMV_DATA" ]]; then
        if __confirm "Remove data directory ($SEMV_DATA)"; then
            if rm -rf "$SEMV_DATA"; then
                okay "Removed data directory";
            else
                warn "Failed to remove data directory";
            fi
        else
            info "Keeping data directory";
        fi
    fi
    
    okay "SEMV uninstalled successfully";
    ret=0;
    return "$ret";
}

do_reset() {
    local ret=1;
    
    info "Resetting SEMV configuration to defaults...";
    
    # Backup existing configuration
    if [[ -d "$SEMV_CONFIG" ]]; then
        local backup_dir="${SEMV_CONFIG}.backup.$(date +%s)";
        if cp -r "$SEMV_CONFIG" "$backup_dir"; then
            info "Backed up existing configuration to: $backup_dir";
        else
            warn "Failed to backup existing configuration";
        fi
    fi
    
    # Remove current configuration
    if [[ -d "$SEMV_CONFIG" ]]; then
        if ! rm -rf "$SEMV_CONFIG"; then
            error "Failed to remove current configuration";
            return 1;
        fi
    fi
    
    # Recreate default configuration
    if ! _ensure_xdg_paths; then
        error "Failed to recreate configuration directories";
        return 1;
    fi
    
    if ! __create_default_config; then
        error "Failed to create default configuration";
        return 1;
    fi
    
    if ! __create_rc_file; then
        error "Failed to create RC file";
        return 1;
    fi
    
    okay "Configuration reset successfully";
    ret=0;
    return "$ret";
}

do_status() {
    local semv_bin="${XDG_BIN:-$HOME/.local/bin}/semv";
    local semv_lib="${XDG_LIB:-$HOME/.local/lib}/fx/semv";
    local status;
    
    info "SEMV Installation Status:";
    
    # Check binary symlink
    if [[ -L "$semv_bin" ]] && [[ -x "$semv_bin" ]]; then
        okay "Binary: $semv_bin ✓";
    else
        warn "Binary: $semv_bin ✗";
    fi
    
    # Check library
    if [[ -f "$semv_lib/semv.sh" ]] && [[ -x "$semv_lib/semv.sh" ]]; then
        okay "Library: $semv_lib ✓";
    else
        warn "Library: $semv_lib ✗";
    fi
    
    # Check configuration
    if [[ -d "$SEMV_CONFIG" ]]; then
        okay "Configuration: $SEMV_CONFIG ✓";
    else
        warn "Configuration: $SEMV_CONFIG ✗";
    fi
    
    # Check data directory
    if [[ -d "$SEMV_DATA" ]]; then
        okay "Data: $SEMV_DATA ✓";
    else
        warn "Data: $SEMV_DATA ✗";
    fi
    
    # Check RC file
    if [[ -f "$SEMV_RC" ]]; then
        okay "RC File: $SEMV_RC ✓";
    else
        warn "RC File: $SEMV_RC ✗";
    fi
    
    return 0;
}

__create_default_config() {
    local config_file="$SEMV_CONFIG/config";
    local ret=1;
    
    if ! mkdir -p "$SEMV_CONFIG"; then
        return 1;
    fi
    
    # Create main configuration file
    cat > "$config_file" << 'EOF'
# SEMV Configuration File
# semv-revision: 2.0.0-dev_1

# Commit label configuration
SEMV_MAJ_LABEL="brk"
SEMV_FEAT_LABEL="feat"
SEMV_FIX_LABEL="fix"
SEMV_DEV_LABEL="dev"

# Build configuration
SEMV_MIN_BUILD=1000

# Default options
DEFAULT_DEBUG=1
DEFAULT_TRACE=1
DEFAULT_QUIET=1
DEFAULT_FORCE=1
DEFAULT_YES=1
DEFAULT_DEV_NOTE=1
DEFAULT_BUILD_DIR=1
DEFAULT_NO_CURSOR=1

# Environment overrides
NO_BUILD_CURSOR=${NO_BUILD_CURSOR:-}
QUIET_MODE=${QUIET_MODE:-}
DEBUG_MODE=${DEBUG_MODE:-}
EOF

    if [[ -f "$config_file" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

__create_rc_file() {
    local ret=1;
    
    if ! mkdir -p "$(dirname "$SEMV_RC")"; then
        return 1;
    fi
    
    # Create RC file with current state
    cat > "$SEMV_RC" << EOF
# SEMV Session State
# Generated: $(date)
# semv-revision: 2.0.0-dev_1

SEMV_INSTALLED=1
SEMV_INSTALL_DATE=$(date +%s)
SEMV_VERSION=2.0.0-dev_1
SEMV_HOME=$SEMV_HOME
SEMV_CONFIG=$SEMV_CONFIG
SEMV_DATA=$SEMV_DATA
EOF

    if [[ -f "$SEMV_RC" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

#-------------------------------------------------------------------------------
# Bump Commands
#-------------------------------------------------------------------------------

do_bump() {
    local force="${1:-1}";
    local latest;
    local new_version;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    # Get current and next versions
    latest=$(do_latest_tag);
    new_version=$(do_next_semver "$force");
    ret=$?;
    
    if [[ "$ret" -eq 0 ]] && [[ -n "$new_version" ]]; then
        trace "Bump: $latest -> $new_version";
        
        if _do_retag "$new_version" "$latest"; then
            okay "Version bumped successfully: $new_version";
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

_do_retag() {
    local new_tag="$1";
    local current_tag="$2";
    local note;
    local ret=1;
    
    if [[ -z "$new_tag" ]]; then
        error "Missing new tag";
        return 1;
    fi
    
    if ! has_semver || ! is_main; then
        error "Can only retag on main branch with existing semver";
        return 1;
    fi
    
    # Check if this is actually a version increase
    if ! do_is_greater "$new_tag" "$current_tag"; then
        error "New version ($new_tag) is not greater than current ($current_tag)";
        return 1;
    fi
    
    # Check for uncommitted changes
    if ! is_not_staged; then
        if __confirm "You have uncommitted changes. Commit them with this tag"; then
            git add --all;
            git commit -m "auto: adding changes for retag @${new_tag}";
        else
            error "Cancelled due to uncommitted changes";
            return 1;
        fi
    fi
    
    # Get tag message
    note=$(__prompt "Tag message" "auto tag bump");
    
    # Create tag
    if __git_tag_create "$new_tag" "$note"; then
        info "Created tag: $new_tag";
        
        # Push tags
        if __git_push_tags "force"; then
            okay "Pushed tags to remote";
            
            # Push commits if confirmed
            if __confirm "Push commits for $new_tag and main to origin"; then
                git push origin "$new_tag";
                git push origin main;
                okay "Pushed commits to remote";
            fi
            ret=0;
        else
            error "Failed to push tags";
        fi
    else
        error "Failed to create tag";
    fi
    
    return "$ret";
}

#-------------------------------------------------------------------------------
# Info Commands
#-------------------------------------------------------------------------------

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
    
    return 0;
}

do_pending() {
    local latest;
    local label="${1:-any}";
    local changes;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    latest=$(do_latest_tag);
    if [[ -n "$latest" ]]; then
        if [[ "$label" != "any" ]]; then
            changes=$(git log "${latest}"..HEAD --grep="^${label}:" --pretty=format:"%h - %s");
        else
            changes=$(git log "${latest}"..HEAD --pretty=format:"%h - %s");
        fi
        
        if [[ -n "$changes" ]]; then
            warn "Found changes ($label) since $latest:";
            printf "%s\n" "$changes" >&2;
            ret=0;
        else
            okay "No labeled ($label:) commits after $latest";
            ret=1;
        fi
    else
        error "No tags found. Try 'semv new' to initialize";
        ret=1;
    fi
    
    return "$ret";
}

do_last() {
    local days;
    local since;
    local semver;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    days=$(do_days_ago);
    since=$(do_since_pretty);
    semver=$(do_latest_tag);
    
    if [[ "$days" -lt 7 ]]; then
        okay "Last commit was $since";
    elif [[ "$days" -lt 30 ]]; then
        warn "Last commit was $since";
    else
        error "Last commit was $since";
    fi
    
    return 0;
}

do_fetch_tags() {
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    __git_fetch_tags;
}

do_tags() {
    local tags;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    tags=$(__git_list_tags);
    info "Repository tags:";
    printf "%s\n" "$tags" >&2;
    
    return 0;
}

do_inspect() {
    info "Available functions:";
    declare -F | grep 'do_' | awk '{print $3}' >&2;
    
    info "Dispatch mappings:";
    info "(Dispatch table inspection not implemented yet)";
    
    return 0;
}

do_label_help() {
    local msg="";
    
    msg+="~~ SEMV Commit Labels ~~\n";
    msg+="${spark} ${green}brk:${x}  -> Breaking changes [Major]\n";
    msg+="${spark} ${green}feat:${x} -> New features [Minor]\n";
    msg+="${spark} ${green}fix:${x}  -> Bug fixes [Patch]\n";
    msg+="${spark} ${green}dev:${x}  -> Development notes [Dev Build]\n";
    
    printf "%b\n" "$msg" >&2;
    return 0;
}

do_auto() {
    local path="$1";
    local cmd="$2";
    
    # Placeholder for auto mode implementation
    error "Auto mode not implemented yet";
    return 1;
}

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