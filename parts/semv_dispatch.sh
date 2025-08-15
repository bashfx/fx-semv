#!/usr/bin/env bash
#
# semv-dispatch.sh - Command Routing and Main Interface
# semv-revision: 2.0.0-dev_1
# BashFX compliant dispatch and main functions
#

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
        st|status)         func_name="do_status";;
        
        # Build Operations
        file)              func_name="do_build_file";;
        bc|build-count)    func_name="do_build_count";;
        bcr|remote-build)  func_name="do_remote_build_count";;
        
        # Repository Management
        new|mark1)         func_name="do_mark_1";;
        can)               func_name="do_can_semver";;
        fetch)             func_name="do_fetch_tags";;
        tags)              func_name="do_tags";;
        snip)              func_name="do_snip";;
        
        # Version Validation
        test)              func_name="do_test_semver";;
        comp|compare)      func_name="do_compare_versions";;
        
        # Remote Operations  
        remote)            func_name="do_latest_remote";;
        upst|upstream)     func_name="do_remote_compare";;
        rbc|remote-build-compare) func_name="do_rbuild_compare";;
        
        # Future Sync Commands (Phase 4)
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

${bld}SYNCHRONIZATION:${x} ${grey}(Future)${x}
    ${green}sync${x}              Auto-detect and sync all sources
    ${green}sync rust${x}         Sync with Cargo.toml
    ${green}sync js${x}           Sync with package.json

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