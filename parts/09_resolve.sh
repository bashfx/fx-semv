#
# 09_resolve.sh - Version Resolution and Conflict Handling
# semv-revision: 2.0.0
# Part of SEMV - Semantic Version Manager
#

################################################################################
#
#  Version Resolution Functions  
#
################################################################################

################################################################################
#
#  resolve_version_conflicts - Main conflict resolution orchestrator
#
################################################################################
# Returns: 0 on successful resolution, 1 on unresolvable conflicts
# Local Variables: ret, project_types, package_version, git_version, semv_version
# Stream Usage: Messages to stderr

resolve_version_conflicts() {
    local source_file="${1:-}";
    local ret=1;
    local project_types;
    local package_version="";
    local git_version; 
    local semv_version;

    info "Analyzing version sources for conflicts...";

    # If a specific source file is provided, extract version from it directly
    if [[ -n "$source_file" ]]; then
        if [[ -f "$source_file" ]]; then
            package_version=$(__extract_version_from_file "$source_file");
            if [[ -z "$package_version" ]]; then
                warn "Could not extract version from: $source_file";
            else
                trace "Using provided source file version: $package_version ($source_file)";
            fi
        else
            warn "Source file not found: $source_file";
        fi
    fi

    # If no override version, fall back to auto detection of project types/files
    if [[ -z "$package_version" ]]; then
        if project_types=$(detect_project_type); then
            package_version=$(_get_package_version "$project_types");
        else
            # No supported project types found; continue with tags-only authority
            warn "No supported package files detected; using tags as authority";
        fi
    fi

    # Get tag and calculated versions
    git_version=$(_latest_tag);
    # Normalize git version to number (strip leading 'v') for potential comparisons
    local git_version_num="${git_version#v}";
    semv_version=$(_calculate_semv_version);

    trace "Package version: ${package_version:-none}";
    trace "Git tag version: ${git_version:-none}";
    trace "Calculated version: ${semv_version:-none}";

    # Analyze version relationships (highest wins policy handled inside)
    if ! _analyze_version_drift "$package_version" "$git_version" "$semv_version"; then
        error "Version analysis failed";
        return 1;
    fi

    ret=0;
    return "$ret";
}

################################################################################
#
#  _get_package_version - Extract version from package file(s)
#
################################################################################  
# Arguments:
#   1: project_types - Space-separated list of project types
# Returns: 0 on success, 1 on failure
# Local Variables: project_types, type, version, highest_version
# Stream Usage: Version string to stdout

_get_package_version() {
    local project_types="$1";
    local type;
    local version;
    local highest_version="";
    
    # Handle multiple project types by finding highest version
    for type in $project_types; do
        version=$(__get_single_package_version "$type");
        if [[ -n "$version" ]]; then
            if [[ -z "$highest_version" ]] || __version_greater "$version" "$highest_version"; then
                highest_version="$version";
            fi
        fi
    done
    
    if [[ -n "$highest_version" ]]; then
        printf "%s\n" "$highest_version";
        return 0;
    fi
    
    return 1;
}

################################################################################
#
#  __get_single_package_version - Extract version from single package file
#
################################################################################
# Arguments:
#   1: project_type - Single project type
# Returns: 0 on success, 1 on failure  
# Local Variables: project_type, version_file, version
# Stream Usage: Version string to stdout

__get_single_package_version() {
    local project_type="$1";
    local version_file;
    local version;
    
    version_file=$(get_version_files "$project_type");
    if [[ -z "$version_file" ]] || [[ ! -f "$version_file" ]]; then
        return 1;
    fi
    
    case "$project_type" in
        rust)
            # Extract: version = "1.2.3" from [package] section
            version=$(awk '
                /^\[package\]/ { in_package=1; next }
                /^\[/ { in_package=0; next }
                in_package && /^version\s*=/ {
                    gsub(/.*=\s*"/, "");
                    gsub(/".*/, "");
                    print;
                    exit;
                }
            ' "$version_file");
            ;;
        javascript)
            # Extract: "version": "1.2.3" from JSON
            version=$(grep '"version"' "$version_file" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/".*//')
            ;;
        python)
            if [[ "$version_file" == "pyproject.toml" ]]; then
                # Extract: version = "1.2.3" from [project] section  
                version=$(awk '
                    /^\[project\]/ { in_project=1; next }
                    /^\[/ { in_project=0; next }
                    in_project && /^version\s*=/ {
                        gsub(/.*=\s*"/, "");
                        gsub(/".*/, "");
                        print;
                        exit;
                    }
                ' "$version_file");
            else
                # Extract from setup.py - more complex parsing needed
                version=$(grep -o 'version[[:space:]]*=[[:space:]]*['"'"'"][^"'"'"']*['"'"'"]' "$version_file" | head -1 | sed 's/.*=[[:space:]]*['"'"'"]//' | sed 's/['"'"'"].*//');
            fi
            ;;
        bash)
            # Extract: # semv-version: 1.2.3 or # version: 1.2.3 (exclude code lines)
            version=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|semv-revision|version):" "$version_file" | grep -v '\$\|"' | head -1 | sed 's/.*:[[:space:]]*//');
            # Clean up version (remove v prefix, whitespace, and trailing text after version)
            version=$(echo "$version" | sed 's/^v//;s/[[:space:]]*$//g' | awk '{print $1}');
            ;;
    esac
    
    if [[ -n "$version" ]]; then
        # Clean up version string (remove v prefix, whitespace)
        version=$(echo "$version" | sed 's/^v//;s/[[:space:]]*//g');
        printf "%s\n" "$version";
        return 0;
    fi
    
    return 1;
}

################################################################################
#
#  _calculate_semv_version - Calculate what semv thinks version should be
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: latest_tag, commits_since, calculated_version
# Stream Usage: Version string to stdout

_calculate_semv_version() {
    local latest_tag;
    local commits_since;
    local calculated_version;
    
    latest_tag=$(_latest_tag);
    if [[ -z "$latest_tag" ]]; then
        # No tags yet - calculate from beginning
        calculated_version=$(do_next_semver);
    else
        # Calculate next version (do_next_semver gets latest tag itself)
        calculated_version=$(do_next_semver);
    fi
    
    if [[ -n "$calculated_version" ]]; then
        printf "%s\n" "$calculated_version";
        return 0;
    fi
    
    return 1;
}

################################################################################
#
#  _analyze_version_drift - Analyze version relationships and resolve conflicts
#
################################################################################
# Arguments:
#   1: package_version - Version from package files
#   2: git_version - Latest git tag version
#   3: semv_version - Calculated semv version  
# Returns: 0 on successful analysis, 1 on failure
# Local Variables: package_version, git_version, semv_version, resolution

_analyze_version_drift() {
    local package_version="$1";
    local git_version="$2"; 
    local semv_version="$3";
    local resolution;
    
    # Handle missing versions
    if [[ -z "$package_version" ]] && [[ -z "$git_version" ]]; then
        info "No existing versions found - proceeding with semv calculation";
        return 0;
    fi
    
    if [[ -z "$package_version" ]]; then
        info "No package version found - using git tags as authority";
        return 0;
    fi
    
    if [[ -z "$git_version" ]]; then
        warn "No git tags found - package version will be used as baseline";
        if ! __create_sync_tag "$package_version"; then
            error "Failed to create sync tag for package version";
            return 1;
        fi
        return 0;
    fi
    
    # Compare versions and determine resolution strategy
    if __version_greater "$package_version" "$git_version"; then
        if __version_greater "$package_version" "$semv_version"; then
            # Package version is highest - semv is behind
            resolution="package_ahead";
        else
            # Package > git, but semv > package (semv got happy)
            resolution="semv_happy";  
        fi
    elif __version_greater "$git_version" "$package_version"; then
        # Git version is higher - package is stale
        resolution="package_stale";
    else
        # Versions are equal
        if __version_greater "$semv_version" "$package_version"; then
            # All equal but semv calculated higher
            resolution="semv_calculated_ahead";
        else
            resolution="versions_aligned";
        fi
    fi
    
    trace "Resolution strategy: $resolution";
    
    # Execute resolution strategy
    case "$resolution" in
        package_ahead)
            __handle_package_ahead "$package_version" "$git_version";
            ;;
        semv_happy)
            __handle_semv_happy "$package_version" "$semv_version";  
            ;;
        package_stale)
            __handle_package_stale "$package_version" "$git_version";
            ;;
        semv_calculated_ahead)
            info "Semv calculated version ahead - proceeding with bump";
            ;;
        versions_aligned)
            info "All version sources aligned - proceeding normally";
            ;;
        *)
            error "Unknown resolution strategy: $resolution";
            return 1;
            ;;
    esac
    
    return 0;
}

################################################################################
#
#  Resolution Strategy Handlers
#
################################################################################

################################################################################
#
#  __handle_package_ahead - Package version higher than git tags
#
################################################################################
# Arguments:
#   1: package_version - Version from package files
#   2: git_version - Version from git tags
# Returns: 0 on success, 1 on failure

__handle_package_ahead() {
    local package_version="$1";
    local git_version="$2";
    
    warn "Version drift detected:";
    warn "  Package version: $package_version";
    warn "  Git tag version: ${git_version:-none}";
    warn "  Semv is behind authoritative package version";
    
    # Check for auto-resolution
    if [[ "$opt_auto" -eq 0 ]]; then
        info "Auto-resolving: creating sync tag for $package_version";
    else
        if ! __confirm "Create sync tag at $package_version to align semv"; then
            error "Version sync cancelled by user";
            return 1;
        fi
    fi
    
    # Create sync tag
    if ! __create_sync_tag "$package_version"; then
        error "Failed to create sync tag";
        return 1;
    fi
    
    # Offer catch-up for minor/patch versions
    __offer_version_catchup "$package_version";
    
    return 0;
}

################################################################################
#
#  __handle_semv_happy - Semv calculated version higher than authoritative sources
#
################################################################################  
# Arguments:
#   1: package_version - Authoritative package version
#   2: semv_version - Over-calculated semv version
# Returns: 0 on success

__handle_semv_happy() {
    local package_version="$1";
    local semv_version="$2";
    
    warn "Semv over-calculation detected:";
    warn "  Package version: $package_version (authoritative)";
    warn "  Semv calculated: $semv_version";
    warn "  Deferring to authoritative package version";
    
    # Create sync tag at package version  
    if ! __create_sync_tag "$package_version"; then
        error "Failed to create authoritative sync tag";
        return 1;
    fi
    
    info "Semv will now count from $package_version baseline";
    return 0;
}

################################################################################
#
#  __handle_package_stale - Package version lower than git tags
#
################################################################################
# Arguments:
#   1: package_version - Stale package version
#   2: git_version - Current git tag version  
# Returns: 0 on success, 1 on failure

__handle_package_stale() {
    local package_version="$1";
    local git_version="$2";
    
    warn "Stale package file detected:";
    warn "  Package version: $package_version";
    warn "  Git tag version: $git_version";
    warn "  Package file needs updating";
    
    if [[ "$opt_auto" -eq 0 ]]; then
        info "Auto-updating package file to $git_version";
        __update_package_version "$git_version";
    else
        if __confirm "Update package file to match git tag ($git_version)"; then
            __update_package_version "$git_version";
        else
            warn "Package file not updated - may cause further conflicts";
        fi
    fi
    
    return 0;
}

################################################################################
#
#  Utility Functions
#
################################################################################

################################################################################
#
#  __create_sync_tag - Create synchronization tag at specified version
#
################################################################################
# Arguments:
#   1: version - Version to tag (without v prefix)
# Returns: 0 on success, 1 on failure

__create_sync_tag() {
    local version="$1";
    local tag_name="v${version}";
    
    if ! _is_git_repo; then
        error "Not in git repository - cannot create sync tag";
        return 1;
    fi
    
    trace "Creating sync tag: $tag_name";
    
    if git tag -a "$tag_name" -m "semv sync: align to package version $version" 2>/dev/null; then
        okay "Created sync tag: $tag_name";
        return 0;
    else
        error "Failed to create sync tag: $tag_name";
        return 1;
    fi
}

################################################################################
#
#  __offer_version_catchup - Offer to catch up minor/patch versions
#
################################################################################
# Arguments:
#   1: base_version - Base version to catch up from
# Returns: 0 always (non-critical)

__offer_version_catchup() {
    local base_version="$1";
    
    # Check environment safety flags
    if [[ "${SEMV_ALL_AUTO_SAFE:-}" == "1" ]]; then
        trace "Auto-catchup disabled by SEMV_ALL_AUTO_SAFE";
        return 0;
    fi
    
    # For now, just inform user - full implementation in Phase 5
    info "Catch-up functionality will be available in future release";
    info "You can manually bump versions as needed from $base_version baseline";
    
    return 0;
}

################################################################################
#
#  __extract_version_from_file - Extract version from a specific file path
#
################################################################################
# Arguments:
#   1: file_path - Path to file containing a version
# Returns: 0 on success, 1 on failure
# Stream Usage: Version (without leading 'v') to stdout

__extract_version_from_file() {
    local file_path="$1";
    local version="";

    if [[ ! -f "$file_path" ]]; then
        return 1;
    fi

    case "$file_path" in
        *package.json)
            version=$(grep -m1 '"version"' "$file_path" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//;s/".*//');
            ;;
        *pyproject.toml)
            version=$(awk '
                /^\[project\]/ { in_project=1; next }
                /^\[/ { in_project=0; next }
                in_project && /^version\s*=/ {
                    gsub(/.*=\s*"/, "");
                    gsub(/".*/, "");
                    print; exit;
                }
            ' "$file_path");
            ;;
        *setup.py)
            version=$(grep -o 'version[[:space:]]*=[[:space:]]*["'\'''][^"'\''']*["'\''']' "$file_path" | head -1 | sed 's/.*=[[:space:]]*["'\''']//; s/["'\''].*$//');
            ;;
        *Cargo.toml)
            version=$(awk '
                /^\[package\]/ { in_package=1; next }
                /^\[/ { in_package=0; next }
                in_package && /^version\s*=/ {
                    gsub(/.*=\s*"/, "");
                    gsub(/".*/, "");
                    print; exit;
                }
            ' "$file_path");
            ;;
        *.sh|*)
            # Default: try bash-style version comments near header
            version=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|semv-revision|version):" "$file_path" | grep -v '\$\|"' | head -1 | sed 's/.*:[[:space:]]*//');
            ;;
    esac

    if [[ -n "$version" ]]; then
        version=$(echo "$version" | sed 's/^v//;s/[[:space:]]*$//g' | awk '{print $1}')
        printf "%s\n" "$version";
        return 0;
    fi

    return 1;
}

################################################################################
#
#  __update_package_version - Update version in package file(s)
#
################################################################################
# Arguments:
#   1: new_version - Version to set (without v prefix)
# Returns: 0 on success, 1 on failure

__update_package_version() {
    local new_version="$1";
    
    # Connect to existing set command functionality
    local project_types;
    if project_types=$(detect_project_type); then
        case "$project_types" in
            rust)
                do_set rust "$new_version";;
            javascript)  
                do_set js "$new_version";;
            python)
                do_set python "$new_version";;
            bash)
                local bash_file;
                bash_file=$(detect_bash_version_file);
                if [[ -n "$bash_file" ]]; then
                    do_set bash "$new_version" "$bash_file";
                fi
                ;;
            *)
                info "Package file update functionality coming in Phase 6";
                info "Please manually update package files to version: $new_version";
                ;;
        esac
    else
        info "Please manually update package files to version: $new_version";
    fi
    
    return 0;
}

################################################################################
#
#  do_drift - Analyze version drift between sources
#
################################################################################
# Returns: 0 if drift detected, 1 if aligned
# Stream Usage: Analysis output to stderr

do_drift() {
    local view_mode
    view_mode=$(get_view_mode)

    # Data view passthrough
    if [[ "$view_mode" == "data" ]]; then
        status_data
        local kd i key val drift="0" pkg git
        IFS=';' read -ra kd <<< "$(status_data 2>/dev/null || true)"
        for i in "${kd[@]}"; do
            key="${i%%=*}"; val="${i#*=}";
            case "$key" in
                pkg) pkg="$val";;
                git) git="$val";;
            esac
        done
        local git_num="${git#v}"
        if [[ -n "$pkg" ]] && [[ -n "$git_num" ]] && [[ "$pkg" != "$git_num" ]]; then
            drift="1"
        else
            drift="0"
        fi
        if [[ "$drift" == "1" ]]; then
            return 0
        else
            return 1
        fi
    fi

    # Human view: use drift_data for consistency
    local data kd i key val pkg git calc drift="0"
    data=$(status_data 2>/dev/null || true)
    IFS=';' read -ra kd <<< "$data"
    for i in "${kd[@]}"; do
        key="${i%%=*}"; val="${i#*=}"
        case "$key" in
            pkg) pkg="$val";;
            git) git="$val";;
            calc) calc="$val";;
        esac
    done
    local git_num="${git#v}"
    if [[ -n "$pkg" ]] && [[ -n "$git_num" ]] && [[ "$pkg" != "$git_num" ]]; then
        drift="1"
    else
        drift="0"
    fi

    local msg=""
    msg+="~~ Version Drift Analysis ~~\n"
    msg+="📦 PKG: [${grey}${pkg:- -none-}${x}]\n"
    msg+="🏷️ GIT: [${grey}${git:- -none-}${x}]\n"
    msg+="🔢 CALC: [${grey}${calc:- -none-}${x}]\n"
    if [[ "$drift" == "1" ]]; then
        msg+="🧭 STATE: [${orange}DRIFT${x}]\n"
        msg+="Run 'semv sync' to resolve version drift.\n"
        view_drift "$msg" drift
        return 0
    else
        msg+="🧭 STATE: [${green}ALIGNED${x}]\n"
        view_drift "$msg" aligned
        return 1
    fi
}

################################################################################
#
#  do_validate - Validate version consistency and project structure
#
################################################################################
# Returns: 0 if valid, 1 if validation failed
# Stream Usage: Validation results to stderr

do_validate() {
    local ret=0;
    local issues=0;
    
    info "Validating project version consistency...";
    
    # Check project structure (non-fatal if tags exist)
    if ! detect_project_type >/dev/null; then
        if has_semver; then
            warn "No supported package files detected; using tags as authority"
        else
            error "Project structure validation failed"
            ((issues++))
        fi
    fi
    
    # Check for version conflicts (do_drift returns 0 on drift, 1 on aligned)
    if do_drift >/dev/null 2>&1; then
        warn "Version drift detected between sources";
        ((issues++));
    fi
    
    # Check git repository state
    if ! is_repo; then
        error "Not in a git repository";
        ((issues++));
    fi
    
    # Check for uncommitted changes (warn only; not a validation failure)
    if ! is_not_staged; then
        warn "Uncommitted changes detected";
        info "Consider committing changes before version operations";
    fi
    
    # Report results
    if [[ "$issues" -eq 0 ]]; then
        okay "Project validation passed - ready for version operations";
        ret=0;
    else
        error "Found $issues validation issues";
        info "Run 'semv drift' for detailed analysis";
        ret=1;
    fi
    
    return "$ret";
}

# Mark resolve as loaded (load guard pattern)
readonly SEMV_RESOLVE_LOADED=1;
