#
# semv-semver.sh - Core Semantic Versioning Business Logic
# semv-revision: 2.0.0
# BashFX compliant semver operations
#

################################################################################
#
#  Core Semver Functions
#
################################################################################

################################################################################
#
#  do_latest_tag - Get latest git tag (any format)
#
################################################################################
# Returns: 0 if tags exist, 1 if none found
# Local Variables: latest, ret
# Outputs: Latest tag to stdout

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

################################################################################
#
#  do_latest_semver - Get latest semantic version tag
#
################################################################################
# Returns: 0 if semver tags exist, 1 if none found
# Local Variables: latest, ret
# Outputs: Latest semver tag to stdout

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

################################################################################
#
#  do_change_count - Analyze commit changes since tag
#
################################################################################
# Arguments:
#   1: tag (optional) - Tag to count from (defaults to latest)
# Returns: 0 if changes found, 1 if no changes
# Local Variables: tag, break_count, feat_count, fix_count, dev_count, ret
# Side Effects: Sets global b_major, b_minor, b_patch, build_s, note_s

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
    
    trace "Changes since $tag: major=$break_count minor=$feat_count patch=$fix_count dev=$dev_count";
    
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

################################################################################
#
#  do_next_semver - Calculate next semantic version
#
################################################################################
# Arguments:
#   1: force (optional) - Skip confirmation if "0"
# Returns: 0 on success, 1 on failure
# Local Variables: tag, parts, major, minor, patch, extra, new_version, ret
# Outputs: Next version to stdout

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
    if [[ $? -ne 0 ]] || [[ -z "$parts" ]]; then
        error "Invalid version format: $tag";
        return 1;
    fi
    
    # Extract version components
    local -a components=($parts);
    major="${components[0]:-0}";
    minor="${components[1]:-0}";
    patch="${components[2]:-0}";
    extra="${components[3]:-}";
    
    # Validate numeric components
    if ! [[ "$major" =~ ^[0-9]+$ ]] || ! [[ "$minor" =~ ^[0-9]+$ ]] || ! [[ "$patch" =~ ^[0-9]+$ ]]; then
        error "Non-numeric version components from: $tag (got major='$major', minor='$minor', patch='$patch')";
        return 1;
    fi
    
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

################################################################################
#
#  Build File Generation
#
################################################################################

################################################################################
#
#  do_build_file - Generate build information file
#
################################################################################
# Arguments:
#   1: filename (optional) - Build file name (default: "build.inf")
# Returns: 0 on success, 1 on failure
# Local Variables: filename, dest, ret

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
        dest="$filename";
    else
        dest="$BUILD_DIR/$filename";
    fi
    
    # Write build cursor file
    if printf "%s\n" "$(date)" > "$dest"; then
        ret=0;
    fi
    
    return "$ret";
}

# Mark semver as loaded (load guard pattern)
readonly SEMV_SEMVER_LOADED=1;
