#
# semv-printers.sh - Output and Printing Functions
# semv-revision: 2.0.0 
# BashFX compliant printer module with predictable variables
#

################################################################################
#
#  Boxy Integration (Optional Enhancement)
#
################################################################################

# Boxy wrapper for enhanced visual output
boxy_msg() {
    local theme="$1";
    local message="$2";
    shift 2;
    
    if [[ "$SEMV_USE_BOXY" == "1" ]] && command_exists boxy; then
        echo "$message" | boxy --theme "$theme" "$@";
    else
        # Fallback to standard messaging
        case "$theme" in
            success) okay "$message" ;;
            error) error "$message" ;;
            warn) warn "$message" ;;
            info) info "$message" ;;
            *) info "$message" ;;
        esac
    fi
}

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
    
    if [[ "$opt_quiet" -eq 0 ]]; then
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
    
    # Determine input source: prefer tty when available
    if [[ -t 0 ]] && [[ -r "/dev/tty" ]]; then
        src="/dev/tty";
    else
        src="/dev/stdin";
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

# Mark printers as loaded (load guard pattern)
readonly SEMV_PRINTERS_LOADED=1;
