#!/usr/bin/env bash
#
# semv-sync-commands.sh - Sync Command Implementation
# semv-revision: 2.0.0-dev_1
# BashFX compliant sync orchestration functions
#

################################################################################
#
#  Main Sync Commands
#
################################################################################

################################################################################
#
#  do_sync - Auto-detect and sync all version sources
#
################################################################################
# Arguments:
#   1: project_type (optional) - Specific project type to sync
# Returns: 0 on success, 1 on failure
# Local Variables: project_type, detected_types, all_versions, highest_version, ret

do_sync() {
    local project_type="$1";
    local -a detected_types;
    local -a all_versions;
    local highest_version;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    info "Starting version synchronization...";
    
    # Validate project structure first
    if ! _validate_project_structure; then
        return 1;
    fi
    
    # Determine project types to sync
    if [[ -n "$project_type" ]]; then
        # Specific project type requested
        detected_types=("$project_type");
        info "Syncing specific project type: $project_type";
    else
        # Auto-detect all project types
        mapfile -t detected_types < <(_detect_project_type);
        if [[ "${#detected_types[@]}" -eq 0 ]]; then
            error "No supported project types detected";
            return 1;
        fi
        info "Detected project types: ${detected_types[*]}";
    fi
    
    # Gather all version sources
    if ! _gather_all_versions all_versions "${detected_types[@]}"; then
        error "Failed to gather version information";
        return 1;
    fi
    
    # Find highest version
    highest_version=$(_find_highest_version "${all_versions[@]}");
    if [[ -z "$highest_version" ]]; then
        error "No valid versions found";
        return 1;
    fi
    
    info "Highest version found: $highest_version";
    
    # Sync all sources to highest version
    if _sync_all_sources "$highest_version" "${detected_types[@]}"; then
        okay "Version synchronization completed successfully";
        info "All sources synced to: $highest_version";
        
        # Update build cursor with sync information
        _update_cursor_sync_info "$highest_version" "${detected_types[0]}";
        
        ret=0;
    else
        error "Failed to synchronize all sources";
    fi
    
    return "$ret";
}

################################################################################
#
#  do_validate - Check all sources are in sync
#
################################################################################
# Returns: 0 if in sync, 1 if not
# Local Variables: detected_types, all_versions, unique_versions, ret

do_validate() {
    local -a detected_types;
    local -a all_versions;
    local -a unique_versions;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    info "Validating version synchronization...";
    
    # Detect project types
    mapfile -t detected_types < <(_detect_project_type);
    if [[ "${#detected_types[@]}" -eq 0 ]]; then
        warn "No supported project types detected";
        return 0;
    fi
    
    # Gather all versions
    if ! _gather_all_versions all_versions "${detected_types[@]}"; then
        error "Failed to gather version information";
        return 1;
    fi
    
    # Check for version consistency
    mapfile -t unique_versions < <(printf "%s\n" "${all_versions[@]}" | sort -u);
    
    if [[ "${#unique_versions[@]}" -eq 1 ]]; then
        okay "All sources are in sync: ${unique_versions[0]}";
        ret=0;
    else
        warn "Version drift detected:";
        _show_version_drift "${detected_types[@]}";
        ret=1;
    fi
    
    return "$ret";
}

################################################################################
#
#  do_drift - Show version mismatches across sources
#
################################################################################
# Returns: 0 always
# Local Variables: detected_types

do_drift() {
    local -a detected_types;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    info "Checking for version drift...";
    
    # Detect project types
    mapfile -t detected_types < <(_detect_project_type);
    if [[ "${#detected_types[@]}" -eq 0 ]]; then
        warn "No supported project types detected";
        return 0;
    fi
    
    # Show version information for each source
    _show_version_drift "${detected_types[@]}";
    
    return 0;
}

################################################################################
#
#  Internal Sync Helper Functions
#
################################################################################

################################################################################
#
#  _gather_all_versions - Collect versions from all sources
#
################################################################################
# Arguments:
#   1: output_array (nameref) - Array to store versions
#   2+: project_types (strings) - Project types to check
# Returns: 0 on success, 1 on failure
# Local Variables: versions_ref, project_type, version, git_version, cursor_version

_gather_all_versions() {
    local -n versions_ref="$1";
    shift;
    local project_type;
    local version;
    local git_version;
    local cursor_version;
    
    versions_ref=();
    
    # Get git tag version
    git_version=$(do_latest_tag 2>/dev/null);
    if [[ -n "$git_version" ]] && is_valid_semver "$git_version"; then
        versions_ref+=("$git_version");
        trace "Git version: $git_version";
    fi
    
    # Get cursor version
    cursor_version=$(__parse_cursor_version 2>/dev/null);
    if [[ -n "$cursor_version" ]] && is_valid_semver "$cursor_version"; then
        versions_ref+=("$cursor_version");
        trace "Cursor version: $cursor_version";
    fi
    
    # Get project-specific versions
    for project_type in "$@"; do
        version=$(_get_project_version "$project_type" 2>/dev/null);
        if [[ -n "$version" ]] && is_valid_semver "$version"; then
            # Normalize version format (add 'v' prefix if missing)
            if [[ ! "$version" =~ ^v ]]; then
                version="v$version";
            fi
            versions_ref+=("$version");
            trace "$project_type version: $version";
        else
            warn "Failed to get valid version from $project_type source";
        fi
    done
    
    if [[ "${#versions_ref[@]}" -eq 0 ]]; then
        return 1;
    fi
    
    return 0;
}

################################################################################
#
#  _find_highest_version - Determine highest version from array
#
################################################################################
# Arguments:
#   1+: versions (strings) - Version strings to compare
# Returns: 0 on success, 1 if no versions
# Local Variables: versions, highest, version
# Outputs: Highest version to stdout

_find_highest_version() {
    local -a versions=("$@");
    local highest="";
    local version;
    
    if [[ "${#versions[@]}" -eq 0 ]]; then
        return 1;
    fi
    
    # Start with first version
    highest="${versions[0]}";
    
    # Compare with each subsequent version
    for version in "${versions[@]:1}"; do
        if do_is_greater "$version" "$highest"; then
            highest="$version";
        fi
    done
    
    printf "%s\n" "$highest";
    return 0;
}

################################################################################
#
#  _sync_all_sources - Update all sources to target version
#
################################################################################
# Arguments:
#   1: target_version (string) - Version to sync to
#   2+: project_types (strings) - Project types to update
# Returns: 0 on success, 1 on failure
# Local Variables: target_version, project_type, clean_version, ret

_sync_all_sources() {
    local target_version="$1";
    shift;
    local project_type;
    local clean_version;
    local ret=0;
    
    # Remove 'v' prefix and dev suffixes for package files
    clean_version="${target_version#v}";
    clean_version="${clean_version%%-*}";
    
    trace "Syncing to target: $target_version (clean: $clean_version)";
    
    # Update each project type
    for project_type in "$@"; do
        case "$project_type" in
            rust)
                if ! __write_cargo_version "$clean_version"; then
                    error "Failed to update Cargo.toml";
                    ret=1;
                fi
                ;;
            js)
                if ! __write_package_version "$clean_version"; then
                    error "Failed to update package.json";
                    ret=1;
                fi
                ;;
            python)
                if ! __write_pyproject_version "$clean_version"; then
                    error "Failed to update pyproject.toml";
                    ret=1;
                fi
                ;;
            bash)
                if ! __write_bash_version "$clean_version"; then
                    error "Failed to update bash script version";
                    ret=1;
                fi
                ;;
            *)
                warn "Unknown project type: $project_type";
                ;;
        esac
    done
    
    # Update build cursor
    if ! __write_cursor_version "$target_version"; then
        warn "Failed to update build cursor";
    fi
    
    return "$ret";
}

################################################################################
#
#  _show_version_drift - Display version information for all sources
#
################################################################################
# Arguments:
#   1+: project_types (strings) - Project types to show
# Local Variables: project_type, version, git_version, cursor_version

_show_version_drift() {
    local project_type;
    local version;
    local git_version;
    local cursor_version;
    
    info "Version source comparison:";
    
    # Show git version
    git_version=$(do_latest_tag 2>/dev/null);
    if [[ -n "$git_version" ]]; then
        info "  Git tags: $git_version";
    else
        warn "  Git tags: none found";
    fi
    
    # Show cursor version
    cursor_version=$(__parse_cursor_version 2>/dev/null);
    if [[ -n "$cursor_version" ]]; then
        info "  Build cursor: $cursor_version";
    else
        warn "  Build cursor: none found";
    fi
    
    # Show project-specific versions
    for project_type in "$@"; do
        version=$(_get_project_version "$project_type" 2>/dev/null);
        if [[ -n "$version" ]]; then
            info "  $project_type: $version";
        else
            warn "  $project_type: failed to parse";
        fi
    done
}

################################################################################
#
#  _update_cursor_sync_info - Update build cursor with sync metadata
#
################################################################################
# Arguments:
#   1: synced_version (string) - Version that was synced to
#   2: primary_source (string) - Primary project type that was synced
# Returns: 0 on success, 1 on failure
# Local Variables: synced_version, primary_source, cursor_file

_update_cursor_sync_info() {
    local synced_version="$1";
    local primary_source="$2";
    local cursor_file=".build";
    
    # Find cursor file
    if [[ -f "build/build.inf" ]]; then
        cursor_file="build/build.inf";
    elif [[ -f "build.inf" ]]; then
        cursor_file="build.inf";
    fi
    
    # Update sync information
    if [[ -f "$cursor_file" ]]; then
        sed -i.tmp \
            -e "s/^SYNC_SOURCE=.*/SYNC_SOURCE=$primary_source/" \
            -e "s/^SYNC_VERSION=.*/SYNC_VERSION=$synced_version/" \
            -e "s/^SYNC_DATE=.*/SYNC_DATE=$(date -Iseconds)/" \
            "$cursor_file";
        
        if [[ $? -eq 0 ]]; then
            rm -f "${cursor_file}.tmp";
            trace "Updated cursor sync info: $primary_source -> $synced_version";
        else
            warn "Failed to update cursor sync info";
            mv "${cursor_file}.tmp" "$cursor_file" 2>/dev/null;
        fi
    fi
    
    return 0;
}

################################################################################
#
#  Language-Specific Sync Commands
#
################################################################################

################################################################################
#
#  do_sync_rust - Sync with Cargo.toml
#
################################################################################
# Returns: 0 on success, 1 on failure

do_sync_rust() {
    if ! is_rust_project; then
        error "Not a Rust project (Cargo.toml not found)";
        return 1;
    fi
    
    do_sync "rust";
}

################################################################################
#
#  do_sync_js - Sync with package.json
#
################################################################################
# Returns: 0 on success, 1 on failure

do_sync_js() {
    if ! is_js_project; then
        error "Not a JavaScript project (package.json not found)";
        return 1;
    fi
    
    do_sync "js";
}

################################################################################
#
#  do_sync_python - Sync with pyproject.toml
#
################################################################################
# Returns: 0 on success, 1 on failure

do_sync_python() {
    if ! is_python_project; then
        error "Not a Python project (pyproject.toml not found)";
        return 1;
    fi
    
    do_sync "python";
}

################################################################################
#
#  do_sync_bash - Sync with bash script metadata
#
################################################################################
# Returns: 0 on success, 1 on failure

do_sync_bash() {
    if ! is_bash_project; then
        error "Not a Bash project (no script with version metadata found)";
        return 1;
    fi
    
    do_sync "bash";
}

# Mark sync-commands as loaded (load guard pattern)
readonly SEMV_SYNC_COMMANDS_LOADED=1;