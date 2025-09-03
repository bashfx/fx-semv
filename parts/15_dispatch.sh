#
# semv-dispatch.sh - Command Routing and Main Interface
# semv-revision: 2.0.0
# BashFX compliant dispatch and main functions
#

################################################################################
#
#  print_version - Show tool version from meta header
#
################################################################################
# Returns: 0 always
# Reads the first matching version meta comment near header

print_version() {
    local file="${SEMV_PATH:-${BASH_SOURCE[0]}}";
    local header;
    local line="";
    local ver="";

    # Only search near header to avoid matching code examples later
    if [[ -r "$file" ]]; then
        header=$(head -n 120 "$file" 2>/dev/null);
        # Prefer explicit semv-version/version/app-version keys
        line=$(printf '%s\n' "$header" | grep -im1 -E '^[#;][[:space:]]*(semv-version|version|app-version)[[:space:]]*:' || true)
        if [[ -z "$line" ]]; then
            # Fallback to semv-revision if no explicit version key is present
            line=$(printf '%s\n' "$header" | grep -im1 -E '^[#;][[:space:]]*semv-revision[[:space:]]*:' || true)
        fi
    fi

    if [[ -n "$line" ]]; then
        # Strip up to colon, then trim whitespace
        ver=$(printf '%s' "$line" | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]+$//');
    fi

    printf "semv %s\n" "${ver:-unknown}";
    return 0;
}

################################################################################
#
#  dispatch - Route commands to appropriate do_* functions
#
################################################################################
# Arguments:
#   1: command (string) - Command to execute
#   2+: args (strings) - Command arguments
# Returns: Command return code or 1 on invalid command
# Local Variables: cmd, arg, arg2, ret

dispatch() {
    local cmd="$1";
    local arg="$2";
    local arg2="$3";
    local ret=0;
    local func_name="";
    
    if [[ $# -gt 0 ]]; then shift; fi # Remove command from args if present
    
    case "$cmd" in
        # Version Operations
        ""|latest|tag)     func_name="do_latest_semver";;
        version|ver)       func_name="do_latest_semver";;
        next|dry)          func_name="do_next_semver";;
        bump)              func_name="do_bump";;
        
        # Project Analysis  
        info)              func_name="do_info";;
        pend|pending)      func_name="do_pending";;
        chg|changes)       func_name="do_change_count";;
        since|last)        func_name="do_last";;
        st|status)         func_name="do_info";;
        gs)                func_name="do_status";;
        
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
        
        # Remote Operations  
        remote)            func_name="do_latest_remote";;
        upst|upstream)     func_name="do_remote_compare";;
        rbc|remote-build-compare) func_name="do_rbuild_compare";;
        
        # Version Get/Set Commands (Phase 4A)
        get)               func_name="do_get";;
        set)               func_name="do_set";;
        
        # Sync Commands (Phase 4B)
        sync)              func_name="do_sync";;
        validate)          func_name="do_validate";;
        drift)             func_name="do_drift";;
        
        # Workflow Commands (Phase 5)
        pre-commit)        func_name="do_pre_commit";;
        release)           func_name="do_release";;
        audit)             func_name="do_audit";;
        
        # Lifecycle Commands
        install)           func_name="do_install";;
        uninstall)         func_name="do_uninstall";;
        reset)             func_name="do_reset";;
        
        # Channel Promotion Commands
        promote)           func_name="do_promote";;
        
        # Hook Management Commands
        hook)              func_name="do_hook";;
        
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
            # Remove first two args if present, leaving only the parameters for the command
            if [[ $# -gt 0 ]]; then shift; fi
            if [[ $# -gt 0 ]]; then shift; fi
            "$func_name" "$arg" "$arg2" "$@";
            ret=$?;
        else
            error "Function $func_name not implemented yet";
            ret=1;
        fi
    fi
    
    return "$ret";
}

################################################################################
#
#  usage - Display help information
#
################################################################################
# Returns: 0 always
# Local Variables: none

usage() {
    local help_text;
    
    printf -v help_text "%s" "
${bld}semv${x} - Semantic Version Manager

${bld}USAGE:${x}
    semv [command] [args] [flags]

${bld}VERSION OPERATIONS:${x}
    ${green}semv${x}              Show current version (default)
    ${green}version${x}           Show current version (alias)
    ${green}next${x}              Calculate next version (dry run) 
    ${green}bump${x}              Create and push new version tag
    ${green}tag${x}               Show latest semantic version tag

${bld}PROJECT ANALYSIS:${x}
    ${green}info${x}              Overall repository and version status
    ${green}status${x}            Alias of 'info' (overall status)
    ${green}st${x}                Alias of 'status'
    ${green}gs${x}                Git working tree status (# changed files)
    ${green}pend${x}              Show pending changes since last tag
    ${green}since${x}             Time since last commit

${bld}BUILD OPERATIONS:${x}
    ${green}file${x}              Generate build info file
    ${green}bc${x}                Show current build count

${bld}REMOTE:${x}
    ${green}remote${x}            Show latest remote semver tag
    ${green}upst${x}              Compare local vs remote semver
    ${green}rbc${x}               Compare local vs remote build counts

${bld}REPOSITORY MANAGEMENT:${x}
    ${green}new${x}               Initialize repo with v0.0.1
    ${green}can${x}               Check if repo can use semver
    ${green}fetch${x}             Fetch remote tags

${bld}WORKFLOW:${x}
    ${green}pre-commit${x}        Validate before committing
    ${green}audit${x}             Summarize repo/version state

${bld}VERSION GET/SET:${x}
    ${green}get all${x}           Show all detected version sources
    ${green}get rust${x}          Show Rust version (Cargo.toml)
    ${green}get js${x}            Show JavaScript version (package.json)
    ${green}get python${x}        Show Python version (pyproject.toml)
    ${green}get bash FILE${x}     Show bash script version comment
    ${green}set TYPE VER [FILE]${x} Update version in specified source

${bld}SYNCHRONIZATION:${x}
    ${green}sync [FILE]${x}       Sync using optional version source file

${bld}FLAGS:${x}
    ${yellow}-h, --help${x}         Show help and exit
    ${yellow}-d, --debug${x}        Enable debug messages
    ${yellow}-t, --trace${x}        Enable trace messages  
    ${yellow}-q, --quiet${x}        Quiet mode (errors only)
    ${yellow}-v, --version${x}      Show version and exit
    ${yellow}-f, --force${x}        Force operations
    ${yellow}-y, --yes${x}          Auto-answer yes to prompts
    ${yellow}-D, --dev${x}          Master dev flag (enables -d, -t)
    ${yellow}-N, --dev-note${x}     Add dev/build suffix to next version
        --dry-run                Dry run mode (show what would happen)
        --view=MODE              View mode: data | simple | full
        --auto / --no-auto         Automation mode (silence prompts) / restore prompts

${bld}COMMIT LABELS:${x}
    ${orange}major|breaking|api:${x}  Major changes → Major bump
    ${orange}feat|feature|add|minor:${x}  New features → Minor bump
    ${orange}fix|patch|bug|hotfix|up:${x}  Fixes/docs → Patch bump
    ${orange}dev:${x}                Development notes → Dev build

${bld}EXAMPLES:${x}
    semv                  # Show current version
    semv bump             # Bump and tag new version
    semv info             # Show project status
    semv get all          # Show all version sources
    semv set rust 1.2.3   # Update Rust version
    semv -d pend          # Debug mode, show pending changes
";

    printf "%s\n" "$help_text" >&2;
    return 0;
}

################################################################################
#
#  main - Primary script entrypoint
#
################################################################################
# Arguments: All command-line arguments ("$@")
# Returns: Script exit code
# Local Variables: orig_args, filtered_args, ret

main() {
    local orig_args=("$@");
    local -a filtered_args;
    local ret=0;
    
    # Parse options first
    if ! options "${orig_args[@]}"; then
        error "Failed to parse options";
        return 1;
    fi

    # Fast path: help flag
    if [[ "${opt_help:-1}" -eq 0 ]]; then
        usage;
        return 0;
    fi
    
    # Fast path: version flag
    if [[ "${opt_version:-1}" -eq 0 ]]; then
        print_version;
        return 0;
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

# Mark dispatch as loaded (load guard pattern)
readonly SEMV_DISPATCH_LOADED=1;

# Main execution handler (only run if script is executed, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@";
fi
