#
# 08_detect.sh - Project Type Detection and Validation
# semv-revision: 2.0.0
# Part of SEMV - Semantic Version Manager
#

################################################################################
#
#  Project Detection Functions
#
################################################################################

################################################################################
#
#  detect_project_type - Identify project ecosystem(s) present
#
################################################################################
# Returns: 0 on success, 1 on failure or ambiguous project
# Local Variables: ret, found_types, type_count
# Stream Usage: Messages to stderr, detected types to stdout

detect_project_type() {
    local ret=1;
    local -a found_types=();
    local type_count;
    
    trace "Detecting project type...";
    
    # Check for Rust (Cargo.toml)
    if [[ -f "Cargo.toml" ]]; then
        if grep -q "^\[package\]" "Cargo.toml" 2>/dev/null; then
            found_types+=("rust");
            trace "Detected Rust project (Cargo.toml with [package])";
        fi
    fi
    
    # Check for JavaScript/Node (package.json)
    if [[ -f "package.json" ]]; then
        if grep -q '"version"' "package.json" 2>/dev/null; then
            found_types+=("javascript");
            trace "Detected JavaScript project (package.json with version)";
        fi
    fi
    
    # Check for Python (pyproject.toml or setup.py)
    if [[ -f "pyproject.toml" ]]; then
        if grep -q "^\[project\]" "pyproject.toml" 2>/dev/null; then
            found_types+=("python");
            trace "Detected Python project (pyproject.toml with [project])";
        fi
    elif [[ -f "setup.py" ]]; then
        if grep -q "version=" "setup.py" 2>/dev/null; then
            found_types+=("python");
            trace "Detected Python project (setup.py with version)";
        fi
    fi
    
    # Check for Bash (look for .semvrc or specified file)
    if [[ -f ".semvrc" ]]; then
        local bash_file;
        bash_file=$(grep "^BASH_VERSION_FILE=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
        if [[ -n "$bash_file" ]] && [[ -f "$bash_file" ]]; then
            if grep -q "# semv-version:" "$bash_file" 2>/dev/null || grep -q "# version:" "$bash_file" 2>/dev/null; then
                found_types+=("bash");
                trace "Detected Bash project (${bash_file} with version comment)";
            fi
        fi
    else
        # Look for common bash script patterns
        local bash_files;
        mapfile -t bash_files < <(find . -maxdepth 2 -name "*.sh" -type f 2>/dev/null)
        for file in "${bash_files[@]}"; do
            if grep -q "# semv-version:" "$file" 2>/dev/null || grep -q "# version:" "$file" 2>/dev/null; then
                found_types+=("bash");
                trace "Detected Bash project (${file} with version comment)";
                break;
            fi
        done
    fi
    
    type_count=${#found_types[@]};
    trace "Found $type_count project types: ${found_types[*]}";
    
    # Validate project structure
    case "$type_count" in
        0)
            error "No supported project types detected";
            info "Supported: Rust (Cargo.toml), JS (package.json), Python (pyproject.toml/setup.py), Bash (version comments)";
            return 1;
            ;;
        1)
            # Single project type - ideal
            printf "%s\n" "${found_types[0]}";
            ret=0;
            ;;
        *)
            # Multiple project types - check if they should sync
            if __should_sync_versions "${found_types[@]}"; then
                # Embedded packages - sync versions
                printf "%s\n" "${found_types[*]}";  # Space-separated list
                ret=0;
            else
                # Ambiguous project structure
                error "Multiple project types detected but they conflict";
                error "Found: ${found_types[*]}";
                error "Use single language per project or configure .semvrc for multi-language sync";
                return 1;
            fi
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  __should_sync_versions - Determine if multiple languages should sync versions
#
################################################################################
# Arguments: List of detected project types
# Returns: 0 if should sync, 1 if conflicting
# Local Variables: ret, has_conflict
# Stream Usage: Messages to stderr

__should_sync_versions() {
    local ret=1;
    local has_conflict=0;
    
    # For now, assume embedded packages should sync
    # Future: Check for submodule markers or .semvrc configuration
    
    # Check for obvious conflicts (future implementation)
    # - Different major versions across package files
    # - Presence of submodule indicators
    # - Explicit .semvrc configuration against syncing
    
    if [[ "$has_conflict" -eq 0 ]]; then
        trace "Multi-language project approved for version sync";
        ret=0;
    else
        trace "Multi-language project has version conflicts";
    fi
    
    return "$ret";
}

################################################################################
#
#  Version File Detection Functions
#
################################################################################

################################################################################
#
#  get_version_files - Get list of version-containing files for project type
#
################################################################################
# Arguments:
#   1: project_type - Type of project (rust, javascript, python, bash)
# Returns: 0 on success, 1 on failure
# Local Variables: project_type, ret
# Stream Usage: File paths to stdout, messages to stderr

get_version_files() {
    local project_type="$1";
    local ret=1;
    
    case "$project_type" in
        rust)
            if [[ -f "Cargo.toml" ]]; then
                printf "Cargo.toml\n";
                ret=0;
            fi
            ;;
        javascript)
            if [[ -f "package.json" ]]; then
                printf "package.json\n";
                ret=0;
            fi
            ;;
        python)
            if [[ -f "pyproject.toml" ]]; then
                printf "pyproject.toml\n";
                ret=0;
            elif [[ -f "setup.py" ]]; then
                printf "setup.py\n";
                ret=0;
            fi
            ;;
        bash)
            local bash_file;
            if [[ -f ".semvrc" ]]; then
                bash_file=$(grep "^BASH_VERSION_FILE=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
                if [[ -n "$bash_file" ]] && [[ -f "$bash_file" ]]; then
                    printf "%s\n" "$bash_file";
                    ret=0;
                fi
            else
                # Find first bash file with version comment
                local bash_files;
                mapfile -t bash_files < <(find . -maxdepth 2 -name "*.sh" -type f 2>/dev/null)
                for file in "${bash_files[@]}"; do
                    if grep -q "# semv-version:" "$file" 2>/dev/null || grep -q "# version:" "$file" 2>/dev/null; then
                        printf "%s\n" "$file";
                        ret=0;
                        break;
                    fi
                done
            fi
            ;;
        *)
            error "Unknown project type: $project_type";
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  is_project_type - Check if current directory contains specified project type
#
################################################################################
# Arguments:
#   1: project_type - Type to check for
# Returns: 0 if project type present, 1 if not
# Local Variables: project_type
# Stream Usage: No output

is_project_type() {
    local project_type="$1";
    
    case "$project_type" in
        rust)
            [[ -f "Cargo.toml" ]] && grep -q "^\[package\]" "Cargo.toml" 2>/dev/null;
            ;;
        javascript)
            [[ -f "package.json" ]] && grep -q '"version"' "package.json" 2>/dev/null;
            ;;
        python)
            ([[ -f "pyproject.toml" ]] && grep -q "^\[project\]" "pyproject.toml" 2>/dev/null) || \
            ([[ -f "setup.py" ]] && grep -q "version=" "setup.py" 2>/dev/null);
            ;;
        bash)
            if [[ -f ".semvrc" ]]; then
                local bash_file;
                bash_file=$(grep "^BASH_VERSION_FILE=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
                [[ -n "$bash_file" ]] && [[ -f "$bash_file" ]] && \
                (grep -q "# semv-version:" "$bash_file" 2>/dev/null || grep -q "# version:" "$bash_file" 2>/dev/null);
            else
                local bash_files;
                mapfile -t bash_files < <(find . -maxdepth 2 -name "*.sh" -type f 2>/dev/null)
                for file in "${bash_files[@]}"; do
                    if grep -q "# semv-version:" "$file" 2>/dev/null || grep -q "# version:" "$file" 2>/dev/null; then
                        return 0;
                    fi
                done
                return 1;
            fi
            ;;
        *)
            return 1;
            ;;
    esac
}