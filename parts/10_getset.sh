#
# 10_getset.sh - Version Get/Set Commands
# semv-revision: 2.0.0-dev_1
# Part of SEMV - Semantic Version Manager
#

################################################################################
#
#  Get Commands - Version Information Retrieval
#
################################################################################

################################################################################
#
#  do_get - Main get command dispatcher
#
################################################################################
# Arguments:
#   1: source_type - Type of source (rust, js, python, bash, all)
#   2: file_path - Optional file path for bash projects
# Returns: 0 on success, 1 on failure
# Local Variables: source_type, file_path, version, ret
# Stream Usage: Version info to stdout, messages to stderr

do_get() {
    local source_type="$1";
    local file_path="${2:-}";
    local version;
    local ret=1;
    
    case "$source_type" in
        rust|cargo)
            version=$(get_rust_version);
            if [[ -n "$version" ]]; then
                printf "rust: %s\n" "$version";
                ret=0;
            else
                error "No Rust version found (Cargo.toml missing or invalid)";
            fi
            ;;
        js|javascript|node|npm)
            version=$(get_javascript_version);
            if [[ -n "$version" ]]; then
                printf "javascript: %s\n" "$version";
                ret=0;
            else
                error "No JavaScript version found (package.json missing or invalid)";
            fi
            ;;
        python|py)
            version=$(get_python_version);
            if [[ -n "$version" ]]; then
                printf "python: %s\n" "$version";
                ret=0;
            else
                error "No Python version found (pyproject.toml/setup.py missing or invalid)";
            fi
            ;;
        bash|sh)
            if [[ -z "$file_path" ]]; then
                # Try to detect bash file automatically
                file_path=$(detect_bash_version_file);
            fi
            
            if [[ -n "$file_path" ]] && [[ -f "$file_path" ]]; then
                version=$(get_bash_version "$file_path");
                if [[ -n "$version" ]]; then
                    printf "bash (%s): %s\n" "$file_path" "$version";
                    ret=0;
                else
                    error "No version comment found in: $file_path";
                fi
            else
                error "Bash file not specified or not found: ${file_path:-auto-detect failed}";
                info "Usage: semv get bash ./my-script.sh";
            fi
            ;;
        all)
            do_get_all;
            ret=$?;
            ;;
        *)
            error "Unknown source type: $source_type";
            info "Supported: rust, javascript, python, bash, all";
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  do_get_all - Show all version sources
#
################################################################################
# Returns: 0 if any versions found, 1 if none found
# Local Variables: found_any, version, project_types, git_version, semv_version
# Stream Usage: Version info to stdout, messages to stderr

do_get_all() {
    local found_any=0;
    local version;
    local project_types;
    local git_version;
    local semv_version;
    
    info "Scanning all version sources...";
    printf "\n";
    
    # Package file versions
    printf "%s=== Package Files ===%s\n" "$bld" "$x";
    
    # Rust
    version=$(get_rust_version 2>/dev/null);
    if [[ -n "$version" ]]; then
        printf "  rust (Cargo.toml): %s\n" "$version";
        found_any=1;
    fi
    
    # JavaScript  
    version=$(get_javascript_version 2>/dev/null);
    if [[ -n "$version" ]]; then
        printf "  javascript (package.json): %s\n" "$version";
        found_any=1;
    fi
    
    # Python
    version=$(get_python_version 2>/dev/null);
    if [[ -n "$version" ]]; then
        printf "  python (pyproject.toml/setup.py): %s\n" "$version";
        found_any=1;
    fi
    
    # Bash
    local bash_file;
    bash_file=$(detect_bash_version_file 2>/dev/null);
    if [[ -n "$bash_file" ]]; then
        version=$(get_bash_version "$bash_file" 2>/dev/null);
        if [[ -n "$version" ]]; then
            printf "  bash (%s): %s\n" "$bash_file" "$version";
            found_any=1;
        fi
    fi
    
    # Git information
    printf "\n%s=== Git Repository ===%s\n" "$bld" "$x";
    
    git_version=$(_latest_tag 2>/dev/null);
    if [[ -n "$git_version" ]]; then
        printf "  latest tag: %s\n" "$git_version";
        found_any=1;
    else
        printf "  latest tag: none\n";
    fi
    
    # Semv calculations
    printf "\n%s=== SEMV Analysis ===%s\n" "$bld" "$x";
    
    semv_version=$(do_next_semver "${git_version:-v0.0.0}" 2>/dev/null);
    if [[ -n "$semv_version" ]]; then
        printf "  calculated next: %s\n" "$semv_version";
        found_any=1;
    fi
    
    # Build information
    local build_number;
    build_number=$(_build_number 2>/dev/null);
    if [[ -n "$build_number" ]]; then
        printf "  build number: %s\n" "$build_number";
    fi
    
    # Project detection summary
    printf "\n%s=== Project Type ===%s\n" "$bld" "$x";
    project_types=$(detect_project_type 2>/dev/null);
    if [[ -n "$project_types" ]]; then
        printf "  detected: %s\n" "$project_types";
    else
        printf "  detected: none/unknown\n";
    fi
    
    if [[ "$found_any" -eq 0 ]]; then
        printf "\n%sNo version information found%s\n" "$yellow" "$x";
        return 1;
    fi
    
    return 0;
}

################################################################################
#
#  Individual Get Functions  
#
################################################################################

################################################################################
#
#  get_rust_version - Extract version from Cargo.toml
#
################################################################################
# Returns: 0 on success, 1 on failure
# Stream Usage: Version to stdout

get_rust_version() {
    if [[ ! -f "Cargo.toml" ]]; then
        return 1;
    fi
    
    __get_single_package_version "rust";
}

################################################################################
#
#  get_javascript_version - Extract version from package.json
#
################################################################################
# Returns: 0 on success, 1 on failure
# Stream Usage: Version to stdout

get_javascript_version() {
    if [[ ! -f "package.json" ]]; then
        return 1;
    fi
    
    __get_single_package_version "javascript";
}

################################################################################
#
#  get_python_version - Extract version from Python package files
#
################################################################################
# Returns: 0 on success, 1 on failure
# Stream Usage: Version to stdout

get_python_version() {
    if [[ ! -f "pyproject.toml" ]] && [[ ! -f "setup.py" ]]; then
        return 1;
    fi
    
    __get_single_package_version "python";
}

################################################################################
#
#  get_bash_version - Extract version from bash file comment
#
################################################################################
# Arguments:
#   1: file_path - Path to bash file
# Returns: 0 on success, 1 on failure
# Stream Usage: Version to stdout

get_bash_version() {
    local file_path="$1";
    
    if [[ ! -f "$file_path" ]]; then
        return 1;
    fi
    
    # Look for semv-version, semv-revision, or version comment (exclude lines with $ or " which are code)
    local version;
    version=$(grep -E "^[[:space:]]*#[[:space:]]*(semv-version|semv-revision|version):" "$file_path" | grep -v '\$\|"' | head -1 | sed 's/.*:[[:space:]]*//');
    
    if [[ -n "$version" ]]; then
        # Clean up version (remove v prefix, whitespace, and trailing text after version)
        version=$(echo "$version" | sed 's/^v//;s/[[:space:]]*$//g' | awk '{print $1}');
        printf "%s\n" "$version";
        return 0;
    fi
    
    return 1;
}

################################################################################
#
#  detect_bash_version_file - Find bash file with version comment
#
################################################################################
# Returns: 0 on success, 1 on failure
# Stream Usage: File path to stdout

detect_bash_version_file() {
    # Check .semvrc first
    if [[ -f ".semvrc" ]]; then
        local bash_file;
        bash_file=$(grep "^BASH_VERSION_FILE=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
        if [[ -n "$bash_file" ]] && [[ -f "$bash_file" ]]; then
            printf "%s\n" "$bash_file";
            return 0;
        fi
    fi
    
    # Search for bash files with version comments
    local bash_files;
    mapfile -t bash_files < <(find . -maxdepth 2 -name "*.sh" -type f 2>/dev/null)
    
    for file in "${bash_files[@]}"; do
        if grep -q -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$file" 2>/dev/null; then
            printf "%s\n" "$file";
            return 0;
        fi
    done
    
    return 1;
}

################################################################################
#
#  Set Commands - Version Information Update
#
################################################################################

################################################################################
#
#  do_set - Main set command dispatcher
#
################################################################################  
# Arguments:
#   1: source_type - Type of source (rust, js, python, bash, all)
#   2: new_version - Version to set
#   3: file_path - Optional file path for bash projects
# Returns: 0 on success, 1 on failure
# Local Variables: source_type, new_version, file_path, ret
# Stream Usage: Success/failure messages to stderr

do_set() {
    local source_type="$1";
    local new_version="$2";
    local file_path="${3:-}";
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "Version required";
        info "Usage: semv set $source_type VERSION [FILE]";
        return 1;
    fi
    
    # Validate version format
    if ! __validate_semver "$new_version"; then
        error "Invalid semantic version format: $new_version";
        info "Expected format: 1.2.3 or v1.2.3";
        return 1;
    fi
    
    # Clean version (remove v prefix)
    new_version=$(echo "$new_version" | sed 's/^v//');
    
    case "$source_type" in
        rust|cargo)
            if set_rust_version "$new_version"; then
                okay "Updated Rust version to: $new_version";
                ret=0;
            else
                error "Failed to update Rust version";
            fi
            ;;
        js|javascript|node|npm)
            if set_javascript_version "$new_version"; then
                okay "Updated JavaScript version to: $new_version";
                ret=0;
            else
                error "Failed to update JavaScript version";
            fi
            ;;
        python|py)
            if set_python_version "$new_version"; then
                okay "Updated Python version to: $new_version";
                ret=0;
            else
                error "Failed to update Python version";
            fi
            ;;
        bash|sh)
            if [[ -z "$file_path" ]]; then
                file_path=$(detect_bash_version_file);
            fi
            
            if [[ -n "$file_path" ]] && [[ -f "$file_path" ]]; then
                if set_bash_version "$file_path" "$new_version"; then
                    okay "Updated Bash version to: $new_version in $file_path";
                    ret=0;
                else
                    error "Failed to update Bash version in: $file_path";
                fi
            else
                error "Bash file not specified or not found: ${file_path:-auto-detect failed}";
                info "Usage: semv set bash VERSION ./my-script.sh";
            fi
            ;;
        all)
            if do_set_all "$new_version"; then
                okay "Updated all package versions to: $new_version";
                ret=0;
            else
                error "Failed to update one or more package versions";
            fi
            ;;
        *)
            error "Unknown source type: $source_type";
            info "Supported: rust, javascript, python, bash, all";
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  do_set_all - Update all detected package versions
#
################################################################################
# Arguments:
#   1: new_version - Version to set everywhere
# Returns: 0 if all updates successful, 1 if any failed
# Local Variables: new_version, success_count, fail_count
# Stream Usage: Progress messages to stderr

do_set_all() {
    local new_version="$1";
    local success_count=0;
    local fail_count=0;
    
    info "Updating all package versions to: $new_version";
    
    # Update each detected project type
    if is_project_type "rust"; then
        if set_rust_version "$new_version"; then
            info "  ✓ Rust (Cargo.toml)";
            ((success_count++));
        else
            warn "  ✗ Rust (Cargo.toml)";
            ((fail_count++));
        fi
    fi
    
    if is_project_type "javascript"; then
        if set_javascript_version "$new_version"; then
            info "  ✓ JavaScript (package.json)";
            ((success_count++));
        else
            warn "  ✗ JavaScript (package.json)";
            ((fail_count++));
        fi
    fi
    
    if is_project_type "python"; then
        if set_python_version "$new_version"; then
            info "  ✓ Python (pyproject.toml/setup.py)";
            ((success_count++));
        else
            warn "  ✗ Python (pyproject.toml/setup.py)";
            ((fail_count++));
        fi
    fi
    
    # Update bash files if detected
    local bash_file;
    bash_file=$(detect_bash_version_file 2>/dev/null);
    if [[ -n "$bash_file" ]]; then
        if set_bash_version "$bash_file" "$new_version"; then
            info "  ✓ Bash ($bash_file)";
            ((success_count++));
        else
            warn "  ✗ Bash ($bash_file)";
            ((fail_count++));
        fi
    fi
    
    # Report results
    if [[ "$success_count" -gt 0 ]]; then
        okay "Updated $success_count package file(s)";
        if [[ "$fail_count" -gt 0 ]]; then
            warn "Failed to update $fail_count package file(s)";
            return 1;
        fi
        return 0;
    else
        error "No package files found to update";
        return 1;
    fi
}

################################################################################
#
#  Individual Set Functions
#
################################################################################

################################################################################
#
#  set_rust_version - Update version in Cargo.toml
#
################################################################################
# Arguments:
#   1: new_version - Version to set
# Returns: 0 on success, 1 on failure

set_rust_version() {
    local new_version="$1";
    
    if [[ ! -f "Cargo.toml" ]]; then
        return 1;
    fi
    
    # Use awk to update version in [package] section
    if awk -v new_ver="$new_version" '
        /^\[package\]/ { in_package=1; print; next }
        /^\[/ { in_package=0; print; next }
        in_package && /^version\s*=/ {
            print "version = \"" new_ver "\""
            next
        }
        { print }
    ' "Cargo.toml" > "Cargo.toml.tmp" && mv "Cargo.toml.tmp" "Cargo.toml"; then
        return 0;
    fi
    
    return 1;
}

################################################################################
#
#  set_javascript_version - Update version in package.json
#
################################################################################
# Arguments:
#   1: new_version - Version to set
# Returns: 0 on success, 1 on failure

set_javascript_version() {
    local new_version="$1";
    
    if [[ ! -f "package.json" ]]; then
        return 1;
    fi
    
    # Use sed to update version field
    if sed -i.bak 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "'"$new_version"'"/' "package.json"; then
        rm -f "package.json.bak" 2>/dev/null;
        return 0;
    fi
    
    return 1;
}

################################################################################
#
#  set_python_version - Update version in Python package files
#
################################################################################
# Arguments:
#   1: new_version - Version to set
# Returns: 0 on success, 1 on failure

set_python_version() {
    local new_version="$1";
    
    if [[ -f "pyproject.toml" ]]; then
        # Update pyproject.toml
        if awk -v new_ver="$new_version" '
            /^\[project\]/ { in_project=1; print; next }
            /^\[/ { in_project=0; print; next }
            in_project && /^version\s*=/ {
                print "version = \"" new_ver "\""
                next
            }
            { print }
        ' "pyproject.toml" > "pyproject.toml.tmp" && mv "pyproject.toml.tmp" "pyproject.toml"; then
            return 0;
        fi
    elif [[ -f "setup.py" ]]; then
        # Update setup.py (basic sed replacement)
        if sed -i.bak 's/version[[:space:]]*=[[:space:]]*['"'"'"][^"'"'"']*['"'"'"]/version="'"$new_version"'"/' "setup.py"; then
            rm -f "setup.py.bak" 2>/dev/null;
            return 0;
        fi
    fi
    
    return 1;
}

################################################################################
#
#  set_bash_version - Update version comment in bash file
#
################################################################################
# Arguments:
#   1: file_path - Path to bash file
#   2: new_version - Version to set
# Returns: 0 on success, 1 on failure

set_bash_version() {
    local file_path="$1";
    local new_version="$2";
    
    if [[ ! -f "$file_path" ]]; then
        return 1;
    fi
    
    # Update existing version comment or add if missing
    if grep -q -E "^[[:space:]]*#[[:space:]]*(semv-version|version):" "$file_path"; then
        # Update existing comment  
        if sed -i.bak "s/^[[:space:]]*#[[:space:]]*\(semv-version\|version\):[[:space:]]*.*$/# semv-version: $new_version/" "$file_path"; then
            rm -f "${file_path}.bak" 2>/dev/null;
            return 0;
        fi
    else
        # Add version comment after shebang
        if sed -i.bak "2i\\
# semv-version: $new_version" "$file_path"; then
            rm -f "${file_path}.bak" 2>/dev/null;
            return 0;
        fi
    fi
    
    return 1;
}

# Mark getset as loaded (load guard pattern)
readonly SEMV_GETSET_LOADED=1;
