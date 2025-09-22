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
# Local Variables: ret, found_types, type_count, bash_pattern
# Stream Usage: Messages to stderr, detected types to stdout

detect_project_type() {
    local ret=1;
    local -a found_types=();
    local type_count;
    local bash_pattern="";
    local manifest_detected=0;
    
    trace "Detecting project type...";
    
    # Check for Rust (Cargo.toml)
    if [[ -f "Cargo.toml" ]]; then
        if grep -q "^\[package\]" "Cargo.toml" 2>/dev/null; then
            found_types+=("rust");
            trace "Detected Rust project (Cargo.toml with [package])";
            manifest_detected=1;
        fi
    fi
    
    # Check for JavaScript/Node (package.json)
    if [[ -f "package.json" ]]; then
        if grep -q '"version"' "package.json" 2>/dev/null; then
            found_types+=("javascript");
            trace "Detected JavaScript project (package.json with version)";
            manifest_detected=1;
        fi
    fi
    
    # Check for Python (pyproject.toml or setup.py)
    if [[ -f "pyproject.toml" ]]; then
        if grep -q "^\[project\]" "pyproject.toml" 2>/dev/null; then
            found_types+=("python");
            trace "Detected Python project (pyproject.toml with [project])";
            manifest_detected=1;
        fi
    elif [[ -f "setup.py" ]]; then
        if grep -q "version=" "setup.py" 2>/dev/null; then
            found_types+=("python");
            trace "Detected Python project (setup.py with version)";
            manifest_detected=1;
        fi
    fi

    # Enhanced Bash project detection with pattern identification
    if [[ "$manifest_detected" -eq 0 ]]; then
        bash_pattern=$(detect_bash_project_pattern);
        if [[ -n "$bash_pattern" ]]; then
            found_types+=("bash");
            trace "Detected Bash project using pattern: $bash_pattern";
        fi
    else
        trace "Skipping bash detection due to manifest-based project discovery";
    fi
    
    type_count=${#found_types[@]};
    trace "Found $type_count project types: ${found_types[*]}";
    
    # Validate project structure
    case "$type_count" in
        0)
            error "No supported project types detected";
            info "Supported: Rust (Cargo.toml), JS (package.json), Python (pyproject.toml/setup.py), Bash (BashFX/scripts with version info)";
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
#  detect_bash_project_pattern - Determine which bash project pattern is present
#
################################################################################
# Returns: 0 on success (pattern found), 1 on failure (no pattern found)
# Local Variables: folder_name, main_script
# Stream Usage: Pattern name to stdout, messages to stderr

detect_bash_project_pattern() {
    local folder_name;
    local main_script;
    local ret=1;
    
    folder_name=$(basename "$(pwd)");
    trace "Checking bash project patterns for folder: $folder_name";
    
    # Pattern 1: BashFX build.sh pattern (build.sh + parts/ + build.map)
    if [[ -f "build.sh" && -d "parts" ]]; then
        if [[ -f "parts/build.map" ]]; then
            # Full BashFX pattern with build.map
            local first_part;
            first_part=$(grep -v "^#" "parts/build.map" | grep -v "^$" | head -n1 | sed 's/.*:[[:space:]]*//' 2>/dev/null);
            if [[ -n "$first_part" && -f "parts/$first_part" ]]; then
                trace "Found first part from build.map: parts/$first_part";
                local version_found="";
                version_found=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "parts/$first_part" 2>/dev/null);
                if [[ -n "$version_found" ]]; then
                    printf "bashfx-buildsh";
                    trace "Found BashFX build.sh pattern with version in parts/$first_part";
                    return 0;
                fi
            fi
        else
            # Has build.sh and parts/ but no build.map - still a build pattern
            local numbered_parts;
            numbered_parts=$(find parts -name "[0-9][0-9]_*.sh" -type f | sort | head -n1 2>/dev/null);
            if [[ -n "$numbered_parts" ]]; then
                local version_found="";
                version_found=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$numbered_parts" 2>/dev/null);
                if [[ -n "$version_found" ]]; then
                    printf "bashfx-buildsh";
                    trace "Found BashFX build.sh pattern (no build.map) with version in $numbered_parts";
                    return 0;
                fi
            fi
        fi
    fi
    
    # Pattern 2: BashFX simple pattern (prefix-name/ folder + name.sh file)
    if [[ "$folder_name" == *-* ]]; then
        local suffix="${folder_name##*-}";
        main_script="${suffix}.sh";
        if [[ -f "$main_script" ]]; then
            local version_found="";
            version_found=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$main_script" 2>/dev/null);
            if [[ -n "$version_found" ]]; then
                printf "bashfx-simple";
                trace "Found BashFX simple pattern: $folder_name -> $main_script with version";
                return 0;
            fi
        fi
    fi
    
    # Pattern 3: Standalone bash script (foldername.sh)
    main_script="${folder_name}.sh";
    if [[ -f "$main_script" ]]; then
        local version_found="";
        version_found=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$main_script" 2>/dev/null);
        if [[ -n "$version_found" ]]; then
            printf "bash-standalone";
            trace "Found standalone bash pattern: $main_script with version";
            return 0;
        fi
    fi
    
    # Pattern 4: Legacy semvrc configuration
    if [[ -f ".semvrc" ]]; then
        local bash_file;
        bash_file=$(grep "^BASH_VERSION_FILE=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
        if [[ -n "$bash_file" ]] && [[ -f "$bash_file" ]]; then
            local version_found="";
            version_found=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$bash_file" 2>/dev/null);
            if [[ -n "$version_found" ]]; then
                printf "bash-semvrc";
                trace "Found semvrc pattern: $bash_file with version";
                return 0;
            fi
        fi
    fi
    
    # Pattern 5: Generic version-commented bash files
    local bash_files;
    mapfile -t bash_files < <(find . -maxdepth 2 -name "*.sh" -type f 2>/dev/null)
    for file in "${bash_files[@]}"; do
        local version_found="";
        version_found=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$file" 2>/dev/null);
        if [[ -n "$version_found" ]]; then
            printf "bash-generic";
            trace "Found generic bash pattern: $file with version";
            return 0;
        fi
    done
    
    trace "No bash project pattern detected";
    return 1;
}

################################################################################
#
#  get_bash_project_file - Get the main version file for detected bash pattern
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: pattern, folder_name, main_script, first_part
# Stream Usage: File path to stdout, messages to stderr

get_bash_project_file() {
    local pattern;
    local folder_name;
    local main_script;
    local first_part;
    local ret=1;
    
    pattern=$(detect_bash_project_pattern);
    if [[ -z "$pattern" ]]; then
        trace "No bash pattern detected, cannot determine project file";
        return 1;
    fi
    
    folder_name=$(basename "$(pwd)");
    
    case "$pattern" in
        bashfx-buildsh)
            # BashFX build.sh pattern - get first part file
            if [[ -f "parts/build.map" ]]; then
                first_part=$(grep -v "^#" "parts/build.map" | grep -v "^$" | head -n1 | sed 's/.*:[[:space:]]*//' 2>/dev/null);
                if [[ -n "$first_part" && -f "parts/$first_part" ]]; then
                    printf "parts/%s" "$first_part";
                    ret=0;
                fi
            else
                # No build.map, find first numbered part
                first_part=$(find parts -name "[0-9][0-9]_*.sh" -type f | sort | head -n1 2>/dev/null);
                if [[ -n "$first_part" ]]; then
                    printf "%s" "$first_part";
                    ret=0;
                fi
            fi
            ;;
        bashfx-simple)
            # BashFX simple pattern - prefix-name/name.sh
            local suffix="${folder_name##*-}";
            main_script="${suffix}.sh";
            if [[ -f "$main_script" ]]; then
                printf "%s" "$main_script";
                ret=0;
            fi
            ;;
        bash-standalone)
            # Standalone pattern - foldername.sh
            main_script="${folder_name}.sh";
            if [[ -f "$main_script" ]]; then
                printf "%s" "$main_script";
                ret=0;
            fi
            ;;
        bash-semvrc)
            # Legacy semvrc pattern
            local bash_file;
            bash_file=$(grep "^BASH_VERSION_FILE=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
            if [[ -n "$bash_file" && -f "$bash_file" ]]; then
                printf "%s" "$bash_file";
                ret=0;
            fi
            ;;
        bash-generic)
            # Generic pattern - first file with version comment
            local bash_files;
            mapfile -t bash_files < <(find . -maxdepth 2 -name "*.sh" -type f 2>/dev/null)
            for file in "${bash_files[@]}"; do
                if grep -q -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$file" 2>/dev/null; then
                    printf "%s" "$file";
                    ret=0;
                    break;
                fi
            done
            ;;
        *)
            trace "Unknown bash pattern: $pattern";
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
