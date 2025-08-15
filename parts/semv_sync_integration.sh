#!/usr/bin/env bash
#
# semv-sync-integration.sh - Integration with Existing Workflow
# semv-revision: 2.0.0-dev_1
# BashFX compliant sync workflow integration
#

################################################################################
#
#  Enhanced Bump Commands with Sync Integration
#
################################################################################

################################################################################
#
#  do_bump_with_sync - Enhanced bump that includes sync operations
#
################################################################################
# Arguments:
#   1: force (optional) - Skip confirmations if "0"
# Returns: 0 on success, 1 on failure
# Local Variables: force, detected_types, has_sync_sources, latest, new_version, ret

do_bump_with_sync() {
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
    
    # Check for sync sources
    mapfile -t detected_types < <(_detect_project_type 2>/dev/null);
    if [[ "${#detected_types[@]}" -gt 0 ]]; then
        has_sync_sources=1;
        info "Sync sources detected: ${detected_types[*]}";
    fi
    
    # Pre-bump sync if sources exist
    if [[ "$has_sync_sources" -eq 1 ]]; then
        info "Performing pre-bump sync...";
        if ! do_validate; then
            warn "Version drift detected before bump";
            if [[ "$force" -ne 0 ]] && ! __confirm "Continue with version drift"; then
                error "Bump cancelled due to version drift";
                return 1;
            fi
            
            # Auto-sync if user confirms
            if __confirm "Auto-sync before bump"; then
                if ! do_sync; then
                    error "Failed to sync before bump";
                    return 1;
                fi
            fi
        fi
    fi
    
    # Get current and next versions
    latest=$(do_latest_tag);
    new_version=$(do_next_semver "$force");
    ret=$?;
    
    if [[ "$ret" -eq 0 ]] && [[ -n "$new_version" ]]; then
        trace "Bump: $latest -> $new_version";
        
        # Create git tag
        if _do_retag "$new_version" "$latest"; then
            okay "Git version bumped successfully: $new_version";
            
            # Post-bump sync if sources exist
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

################################################################################
#
#  Enhanced Info Commands with Sync Information
#
################################################################################

################################################################################
#
#  do_info_with_sync - Enhanced info that includes sync status
#
################################################################################
# Returns: 0 on success
# Local Variables: detected_types, has_sync_sources, sync_status

do_info_with_sync() {
    local -a detected_types;
    local has_sync_sources=0;
    local sync_status;
    
    # Call original info function
    do_info;
    
    # Add sync information if available
    mapfile -t detected_types < <(_detect_project_type 2>/dev/null);
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

################################################################################
#
#  _show_last_sync_info - Display last sync information from cursor
#
################################################################################
# Local Variables: cursor_file, sync_source, sync_version, sync_date

_show_last_sync_info() {
    local cursor_file=".build";
    local sync_source;
    local sync_version;
    local sync_date;
    
    # Find cursor file
    if [[ -f "build/build.inf" ]]; then
        cursor_file="build/build.inf";
    elif [[ -f "build.inf" ]]; then
        cursor_file="build.inf";
    fi
    
    if [[ -f "$cursor_file" ]]; then
        sync_source=$(grep "^SYNC_SOURCE=" "$cursor_file" 2>/dev/null | cut -d'=' -f2);
        sync_version=$(grep "^SYNC_VERSION=" "$cursor_file" 2>/dev/null | cut -d'=' -f2);
        sync_date=$(grep "^SYNC_DATE=" "$cursor_file" 2>/dev/null | cut -d'=' -f2);
        
        if [[ -n "$sync_source" ]] && [[ -n "$sync_version" ]]; then
            info "Last sync: $sync_source -> $sync_version";
            if [[ -n "$sync_date" ]]; then
                info "Sync date: $sync_date";
            fi
        else
            trace "No previous sync information found";
        fi
    fi
}

################################################################################
#
#  Workflow Integration Commands
#
################################################################################

################################################################################
#
#  do_pre_commit - Pre-commit validation hook
#
################################################################################
# Returns: 0 if ready to commit, 1 if issues found

do_pre_commit() {
    local -a detected_types;
    local ret=0;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    info "Running pre-commit validation...";
    
    # Check for sync sources
    mapfile -t detected_types < <(_detect_project_type 2>/dev/null);
    if [[ "${#detected_types[@]}" -eq 0 ]]; then
        okay "No sync sources - pre-commit validation passed";
        return 0;
    fi
    
    info "Checking sync status for: ${detected_types[*]}";
    
    # Validate sync status
    if do_validate >/dev/null 2>&1; then
        okay "All sources are in sync";
    else
        error "Version drift detected - commit blocked";
        warn "Run 'semv sync' to synchronize versions before committing";
        ret=1;
    fi
    
    # Check for uncommitted changes to version files
    if _check_version_files_staged "${detected_types[@]}"; then
        warn "Version files have unstaged changes";
        if __confirm "Stage version files automatically"; then
            _stage_version_files "${detected_types[@]}";
            okay "Version files staged";
        else
            warn "Version files remain unstaged";
        fi
    fi
    
    return "$ret";
}

################################################################################
#
#  _check_version_files_staged - Check if version files are staged
#
################################################################################
# Arguments:
#   1+: project_types (strings) - Project types to check
# Returns: 0 if unstaged changes exist, 1 if all staged
# Local Variables: project_type, file_changed

_check_version_files_staged() {
    local project_type;
    local file_changed=0;
    
    for project_type in "$@"; do
        case "$project_type" in
            rust)
                if git diff --name-only | grep -q "^Cargo.toml$"; then
                    file_changed=1;
                fi
                ;;
            js)
                if git diff --name-only | grep -q "^package.json$"; then
                    file_changed=1;
                fi
                ;;
            python)
                if git diff --name-only | grep -q "^pyproject.toml$"; then
                    file_changed=1;
                fi
                ;;
            bash)
                if git diff --name-only | grep -q "\.sh$"; then
                    file_changed=1;
                fi
                ;;
        esac
    done
    
    return "$file_changed";
}

################################################################################
#
#  _stage_version_files - Stage version files for commit
#
################################################################################
# Arguments:
#   1+: project_types (strings) - Project types to stage
# Local Variables: project_type

_stage_version_files() {
    local project_type;
    
    for project_type in "$@"; do
        case "$project_type" in
            rust)
                if [[ -f "Cargo.toml" ]]; then
                    git add Cargo.toml;
                    trace "Staged Cargo.toml";
                fi
                ;;
            js)
                if [[ -f "package.json" ]]; then
                    git add package.json;
                    trace "Staged package.json";
                fi
                ;;
            python)
                if [[ -f "pyproject.toml" ]]; then
                    git add pyproject.toml;
                    trace "Staged pyproject.toml";
                fi
                ;;
            bash)
                # Stage bash scripts with version metadata
                local -a script_files;
                mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null);
                local file;
                for file in "${script_files[@]}"; do
                    if [[ -f "$file" ]] && grep -q "^# version:" "$file" 2>/dev/null; then
                        git add "$file";
                        trace "Staged $file";
                    fi
                done
                ;;
        esac
    done
    
    # Stage build cursor if it exists
    local cursor_file;
    for cursor_file in ".build" "build.inf" "build/build.inf"; do
        if [[ -f "$cursor_file" ]]; then
            git add "$cursor_file";
            trace "Staged $cursor_file";
            break;
        fi
    done
}

################################################################################
#
#  do_release - Full release workflow
#
################################################################################
# Returns: 0 on success, 1 on failure

do_release() {
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    info "Starting full release workflow...";
    
    # Pre-release validation
    if ! do_pre_commit; then
        error "Pre-release validation failed";
        return 1;
    fi
    
    # Enhanced bump with sync
    if do_bump_with_sync; then
        okay "Release completed successfully";
        
        # Show final status
        do_info_with_sync;
        ret=0;
    else
        error "Release failed during bump";
    fi
    
    return "$ret";
}

################################################################################
#
#  Override Standard Commands with Sync-Aware Versions
#
################################################################################

# These functions can optionally replace the standard versions
# when sync features are enabled

################################################################################
#
#  Enhanced Build File with Sync Metadata
#
################################################################################

################################################################################
#
#  do_build_file_with_sync - Enhanced build file generation
#
################################################################################
# Arguments:
#   1: filename (optional) - Build file name (default: "build.inf")
# Returns: 0 on success, 1 on failure

do_build_file_with_sync() {
    local filename="${1:-build.inf}";
    
    # Call standard build file generation
    if do_build_file "$filename"; then
        # Add sync metadata if sync sources exist
        local -a detected_types;
        mapfile -t detected_types < <(_detect_project_type 2>/dev/null);
        
        if [[ "${#detected_types[@]}" -gt 0 ]]; then
            _update_cursor_sync_info "$(do_latest_tag)" "${detected_types[0]}";
        fi
        
        return 0;
    else
        return 1;
    fi
}

# Mark sync-integration as loaded (load guard pattern)
readonly SEMV_SYNC_INTEGRATION_LOADED=1;