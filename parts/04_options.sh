#
# semv-options.sh - Flag Parsing and Options
# semv-revision: 2.0.0
# BashFX compliant options module
#

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
            --auto)
                # Enable automation mode (silence ceremonies/prompts)
                opt_auto=0;
                ;;
            --no-auto)
                # Disable automation mode (allow ceremonies/prompts)
                opt_auto=1;
                ;;
            --view=*)
                # Set view mode (data/simple/full)
                opt_view="${this#*=}";
                ;;
            --view)
                # Set view mode with next argument
                if [[ -n "$next" ]] && [[ ! "$next" =~ ^- ]]; then
                    opt_view="$next";
                    ((i++));
                else
                    opt_view="simple";
                fi
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

# Mark options as loaded (load guard pattern)
readonly SEMV_OPTIONS_LOADED=1;
