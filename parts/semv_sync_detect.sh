#!/usr/bin/env bash
#
# semv-sync-detect.sh - Project Detection and Language Support
# semv-revision: 2.0.0-dev_1
# BashFX compliant sync detection module
#

################################################################################
#
#  Project Detection Functions
#
################################################################################

################################################################################
#
#  _detect_project_type - Auto-detect project language type
#
################################################################################
# Returns: 0 if project detected, 1 if none found
# Local Variables: detected_types, ret
# Outputs: Detected project type(s) to stdout (space-separated)
# Side Effects: Sets global PROJECT_TYPES array

_detect_project_type() {
    local -a detected_types=();
    local ret=1;
    
    # Check for Rust project
    if [[ -f "Cargo.toml" ]]; then
        detected_types+=("rust");
        trace "Detected Rust project (Cargo.toml found)";
        ret=0;
    fi
    
    # Check for Node.js project
    if [[ -f "package.json" ]]; then
        detected_types+=("js");
        trace "Detected JavaScript project (package.json found)";
        ret=0;
    fi
    
    # Check for Python project
    if [[ -f "pyproject.toml" ]]; then
        detected_types+=("python");
        trace "Detected Python project (pyproject.toml found)";
        ret=0;
    fi
    
    # Check for Bash script project (look for main script with version meta)
    if _detect_bash_project; then
        detected_types+=("bash");
        trace "Detected Bash project (script with version meta found)";
        ret=0;
    fi
    
    # Store globally for other functions
    PROJECT_TYPES=("${detected_types[@]}");
    
    # Output detected types
    if [[ "${#detected_types[@]}" -gt 0 ]]; then
        printf "%s\n" "${detected_types[*]}";
    fi
    
    return "$ret";
}

################################################################################
#
#  _detect_bash_project - Check for bash script with version metadata
#
################################################################################
# Returns: 0 if bash project detected, 1 if not
# Local Variables: script_files, file

_detect_bash_project() {
    local -a script_files;
    local file;
    
    # Look for executable bash scripts with version metadata
    mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null);
    
    for file in "${script_files[@]}"; do
        if [[ -f "$file" ]] && grep -q "^# version:" "$file" 2>/dev/null; then
            trace "Found bash script with version meta: $file";
            return 0;
        fi
    done
    
    return 1;
}

################################################################################
#
#  _validate_project_structure - Ensure single version source per type
#
################################################################################
# Returns: 0 if valid structure, 1 if conflicts
# Local Variables: rust_files, js_files, python_files, ret

_validate_project_structure() {
    local -a rust_files;
    local -a js_files;
    local -a python_files;
    local ret=0;
    
    # Check for multiple Rust manifests in root
    mapfile -t rust_files < <(find . -maxdepth 1 -name "Cargo.toml" 2>/dev/null);
    if [[ "${#rust_files[@]}" -gt 1 ]]; then
        error "Multiple Cargo.toml files found in root directory";
        ret=1;
    fi
    
    # Check for multiple package.json files in root
    mapfile -t js_files < <(find . -maxdepth 1 -name "package.json" 2>/dev/null);
    if [[ "${#js_files[@]}" -gt 1 ]]; then
        error "Multiple package.json files found in root directory";
        ret=1;
    fi
    
    # Check for multiple pyproject.toml files in root
    mapfile -t python_files < <(find . -maxdepth 1 -name "pyproject.toml" 2>/dev/null);
    if [[ "${#python_files[@]}" -gt 1 ]]; then
        error "Multiple pyproject.toml files found in root directory";
        ret=1;
    fi
    
    if [[ "$ret" -eq 1 ]]; then
        error "Project structure has conflicts - cannot determine single version source";
    fi
    
    return "$ret";
}

################################################################################
#
#  _get_project_version - Extract version from detected project type
#
################################################################################
# Arguments:
#   1: project_type (string) - Project type to get version from
# Returns: 0 on success, 1 on failure
# Local Variables: project_type, version, ret
# Outputs: Version string to stdout

_get_project_version() {
    local project_type="$1";
    local version;
    local ret=1;
    
    if [[ -z "$project_type" ]]; then
        error "Project type required";
        return 1;
    fi
    
    case "$project_type" in
        rust)
            version=$(__parse_cargo_version);
            ret=$?;
            ;;
        js)
            version=$(__parse_package_version);
            ret=$?;
            ;;
        python)
            version=$(__parse_pyproject_version);
            ret=$?;
            ;;
        bash)
            version=$(__parse_bash_version);
            ret=$?;
            ;;
        *)
            error "Unsupported project type: $project_type";
            return 1;
            ;;
    esac
    
    if [[ "$ret" -eq 0 ]] && [[ -n "$version" ]]; then
        printf "%s\n" "$version";
    else
        error "Failed to extract version from $project_type project";
    fi
    
    return "$ret";
}

################################################################################
#
#  Project Type Validation Functions
#
################################################################################

################################################################################
#
#  is_rust_project - Check if current directory is a Rust project
#
################################################################################
# Returns: 0 if Rust project, 1 if not

is_rust_project() {
    [[ -f "Cargo.toml" ]];
}

################################################################################
#
#  is_js_project - Check if current directory is a JavaScript project
#
################################################################################
# Returns: 0 if JavaScript project, 1 if not

is_js_project() {
    [[ -f "package.json" ]];
}

################################################################################
#
#  is_python_project - Check if current directory is a Python project
#
################################################################################
# Returns: 0 if Python project, 1 if not

is_python_project() {
    [[ -f "pyproject.toml" ]];
}

################################################################################
#
#  is_bash_project - Check if current directory is a Bash project
#
################################################################################
# Returns: 0 if Bash project, 1 if not

is_bash_project() {
    _detect_bash_project;
}

################################################################################
#
#  Multi-Project Detection Functions
#
################################################################################

################################################################################
#
#  has_multiple_project_types - Check if multiple project types detected
#
################################################################################
# Returns: 0 if multiple types, 1 if single or none
# Local Variables: detected_types

has_multiple_project_types() {
    local -a detected_types;
    
    # Use global if available, otherwise detect
    if [[ "${#PROJECT_TYPES[@]}" -gt 0 ]]; then
        detected_types=("${PROJECT_TYPES[@]}");
    else
        mapfile -t detected_types < <(_detect_project_type);
    fi
    
    [[ "${#detected_types[@]}" -gt 1 ]];
}

################################################################################
#
#  get_primary_project_type - Determine primary project type
#
################################################################################
# Returns: 0 on success, 1 if no projects or conflicts
# Local Variables: detected_types, primary_type
# Outputs: Primary project type to stdout

get_primary_project_type() {
    local -a detected_types;
    local primary_type;
    
    # Detect project types if not already done
    if [[ "${#PROJECT_TYPES[@]}" -eq 0 ]]; then
        mapfile -t detected_types < <(_detect_project_type);
        PROJECT_TYPES=("${detected_types[@]}");
    else
        detected_types=("${PROJECT_TYPES[@]}");
    fi
    
    # Handle different scenarios
    case "${#detected_types[@]}" in
        0)
            error "No supported project types detected";
            return 1;
            ;;
        1)
            primary_type="${detected_types[0]}";
            trace "Single project type detected: $primary_type";
            ;;
        *)
            # Multiple types - use priority order
            if [[ " ${detected_types[*]} " =~ " rust " ]]; then
                primary_type="rust";
                trace "Multiple types detected, prioritizing Rust";
            elif [[ " ${detected_types[*]} " =~ " js " ]]; then
                primary_type="js";
                trace "Multiple types detected, prioritizing JavaScript";
            elif [[ " ${detected_types[*]} " =~ " python " ]]; then
                primary_type="python";
                trace "Multiple types detected, prioritizing Python";
            elif [[ " ${detected_types[*]} " =~ " bash " ]]; then
                primary_type="bash";
                trace "Multiple types detected, using Bash";
            else
                error "Cannot determine primary project type from: ${detected_types[*]}";
                return 1;
            fi
            ;;
    esac
    
    printf "%s\n" "$primary_type";
    return 0;
}

################################################################################
#
#  Global Variables for Project State
#
################################################################################

# Array to store detected project types (set by _detect_project_type)
declare -ga PROJECT_TYPES=();

# Mark sync-detect as loaded (load guard pattern)
readonly SEMV_SYNC_DETECT_LOADED=1;