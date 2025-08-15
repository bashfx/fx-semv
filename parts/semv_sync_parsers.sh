#!/usr/bin/env bash
#
# semv-sync-parsers.sh - Version Source Parsing Functions
# semv-revision: 2.0.0-dev_1
# BashFX compliant version parsing for multiple languages
#

################################################################################
#
#  Rust Version Parsing
#
################################################################################

################################################################################
#
#  __parse_cargo_version - Extract version from Cargo.toml
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: cargo_file, version, ret
# Outputs: Version string to stdout

__parse_cargo_version() {
    local cargo_file="Cargo.toml";
    local version;
    local ret=1;
    
    if [[ ! -f "$cargo_file" ]]; then
        error "Cargo.toml not found";
        return 1;
    fi
    
    # Parse version from [package] section
    version=$(awk '
        /^\[package\]/ { in_package = 1; next }
        /^\[/ { in_package = 0; next }
        in_package && /^version[[:space:]]*=[[:space:]]*/ {
            gsub(/^version[[:space:]]*=[[:space:]]*/, "")
            gsub(/^["'"'"']/, "")
            gsub(/["'"'"'].*$/, "")
            print
            exit
        }
    ' "$cargo_file");
    
    if [[ -n "$version" ]]; then
        printf "%s\n" "$version";
        ret=0;
    else
        error "Failed to parse version from Cargo.toml";
    fi
    
    return "$ret";
}

################################################################################
#
#  __write_cargo_version - Update version in Cargo.toml
#
################################################################################
# Arguments:
#   1: new_version (string) - New version to write
# Returns: 0 on success, 1 on failure
# Local Variables: new_version, cargo_file, backup_file, ret

__write_cargo_version() {
    local new_version="$1";
    local cargo_file="Cargo.toml";
    local backup_file="${cargo_file}.semv-backup";
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "Version required";
        return 1;
    fi
    
    if [[ ! -f "$cargo_file" ]]; then
        error "Cargo.toml not found";
        return 1;
    fi
    
    # Create backup
    if ! cp "$cargo_file" "$backup_file"; then
        error "Failed to create backup of Cargo.toml";
        return 1;
    fi
    
    # Update version using awk
    awk -v new_ver="$new_version" '
        /^\[package\]/ { in_package = 1; print; next }
        /^\[/ { in_package = 0; print; next }
        in_package && /^version[[:space:]]*=[[:space:]]*/ {
            print "version = \"" new_ver "\""
            next
        }
        { print }
    ' "$backup_file" > "$cargo_file";
    
    if [[ $? -eq 0 ]]; then
        trace "Updated Cargo.toml version to $new_version";
        rm "$backup_file";
        ret=0;
    else
        error "Failed to update Cargo.toml";
        mv "$backup_file" "$cargo_file";
    fi
    
    return "$ret";
}

################################################################################
#
#  JavaScript Version Parsing
#
################################################################################

################################################################################
#
#  __parse_package_version - Extract version from package.json
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: package_file, version, ret
# Outputs: Version string to stdout

__parse_package_version() {
    local package_file="package.json";
    local version;
    local ret=1;
    
    if [[ ! -f "$package_file" ]]; then
        error "package.json not found";
        return 1;
    fi
    
    # Parse version using awk (avoid jq dependency)
    version=$(awk -F'"' '
        /"version"[[:space:]]*:[[:space:]]*"/ {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /version/) {
                    print $(i+2)
                    exit
                }
            }
        }
    ' "$package_file");
    
    if [[ -n "$version" ]]; then
        printf "%s\n" "$version";
        ret=0;
    else
        error "Failed to parse version from package.json";
    fi
    
    return "$ret";
}

################################################################################
#
#  __write_package_version - Update version in package.json
#
################################################################################
# Arguments:
#   1: new_version (string) - New version to write
# Returns: 0 on success, 1 on failure
# Local Variables: new_version, package_file, backup_file, ret

__write_package_version() {
    local new_version="$1";
    local package_file="package.json";
    local backup_file="${package_file}.semv-backup";
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "Version required";
        return 1;
    fi
    
    if [[ ! -f "$package_file" ]]; then
        error "package.json not found";
        return 1;
    fi
    
    # Create backup
    if ! cp "$package_file" "$backup_file"; then
        error "Failed to create backup of package.json";
        return 1;
    fi
    
    # Update version using sed
    if sed -i.tmp 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "'$new_version'"/' "$package_file"; then
        trace "Updated package.json version to $new_version";
        rm -f "${package_file}.tmp" "$backup_file";
        ret=0;
    else
        error "Failed to update package.json";
        mv "$backup_file" "$package_file";
    fi
    
    return "$ret";
}

################################################################################
#
#  Python Version Parsing
#
################################################################################

################################################################################
#
#  __parse_pyproject_version - Extract version from pyproject.toml
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: pyproject_file, version, ret
# Outputs: Version string to stdout

__parse_pyproject_version() {
    local pyproject_file="pyproject.toml";
    local version;
    local ret=1;
    
    if [[ ! -f "$pyproject_file" ]]; then
        error "pyproject.toml not found";
        return 1;
    fi
    
    # Parse version from [project] section
    version=$(awk '
        /^\[project\]/ { in_project = 1; next }
        /^\[/ { in_project = 0; next }
        in_project && /^version[[:space:]]*=[[:space:]]*/ {
            gsub(/^version[[:space:]]*=[[:space:]]*/, "")
            gsub(/^["'"'"']/, "")
            gsub(/["'"'"'].*$/, "")
            print
            exit
        }
    ' "$pyproject_file");
    
    if [[ -n "$version" ]]; then
        printf "%s\n" "$version";
        ret=0;
    else
        error "Failed to parse version from pyproject.toml";
    fi
    
    return "$ret";
}

################################################################################
#
#  __write_pyproject_version - Update version in pyproject.toml
#
################################################################################
# Arguments:
#   1: new_version (string) - New version to write
# Returns: 0 on success, 1 on failure
# Local Variables: new_version, pyproject_file, backup_file, ret

__write_pyproject_version() {
    local new_version="$1";
    local pyproject_file="pyproject.toml";
    local backup_file="${pyproject_file}.semv-backup";
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "Version required";
        return 1;
    fi
    
    if [[ ! -f "$pyproject_file" ]]; then
        error "pyproject.toml not found";
        return 1;
    fi
    
    # Create backup
    if ! cp "$pyproject_file" "$backup_file"; then
        error "Failed to create backup of pyproject.toml";
        return 1;
    fi
    
    # Update version using awk
    awk -v new_ver="$new_version" '
        /^\[project\]/ { in_project = 1; print; next }
        /^\[/ { in_project = 0; print; next }
        in_project && /^version[[:space:]]*=[[:space:]]*/ {
            print "version = \"" new_ver "\""
            next
        }
        { print }
    ' "$backup_file" > "$pyproject_file";
    
    if [[ $? -eq 0 ]]; then
        trace "Updated pyproject.toml version to $new_version";
        rm "$backup_file";
        ret=0;
    else
        error "Failed to update pyproject.toml";
        mv "$backup_file" "$pyproject_file";
    fi
    
    return "$ret";
}

################################################################################
#
#  Bash Version Parsing
#
################################################################################

################################################################################
#
#  __parse_bash_version - Extract version from bash script metadata
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: script_files, file, version, ret
# Outputs: Version string to stdout

__parse_bash_version() {
    local -a script_files;
    local file;
    local version;
    local ret=1;
    
    # Find bash scripts with version metadata
    mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null);
    
    for file in "${script_files[@]}"; do
        if [[ -f "$file" ]]; then
            version=$(grep "^# version:" "$file" 2>/dev/null | head -1 | sed 's/^# version:[[:space:]]*//' | tr -d ' ');
            if [[ -n "$version" ]]; then
                printf "%s\n" "$version";
                ret=0;
                break;
            fi
        fi
    done
    
    if [[ "$ret" -ne 0 ]]; then
        error "No bash script with version metadata found";
    fi
    
    return "$ret";
}

################################################################################
#
#  __write_bash_version - Update version in bash script metadata
#
################################################################################
# Arguments:
#   1: new_version (string) - New version to write
# Returns: 0 on success, 1 on failure
# Local Variables: new_version, script_files, file, backup_file, ret

__write_bash_version() {
    local new_version="$1";
    local -a script_files;
    local file;
    local backup_file;
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "Version required";
        return 1;
    fi
    
    # Find bash scripts with version metadata
    mapfile -t script_files < <(find . -maxdepth 2 -name "*.sh" -executable 2>/dev/null);
    
    for file in "${script_files[@]}"; do
        if [[ -f "$file" ]] && grep -q "^# version:" "$file" 2>/dev/null; then
            backup_file="${file}.semv-backup";
            
            # Create backup
            if ! cp "$file" "$backup_file"; then
                error "Failed to create backup of $file";
                continue;
            fi
            
            # Update version using sed
            if sed -i.tmp "s/^# version:.*/# version: $new_version/" "$file"; then
                trace "Updated $file version to $new_version";
                rm -f "${file}.tmp" "$backup_file";
                ret=0;
                break;
            else
                error "Failed to update $file";
                mv "$backup_file" "$file";
            fi
        fi
    done
    
    if [[ "$ret" -ne 0 ]]; then
        error "No bash script with version metadata found to update";
    fi
    
    return "$ret";
}

################################################################################
#
#  Build Cursor Parsing
#
################################################################################

################################################################################
#
#  __parse_cursor_version - Extract version from .build file
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: cursor_file, version, ret
# Outputs: Version string to stdout

__parse_cursor_version() {
    local cursor_file=".build";
    local version;
    local ret=1;
    
    # Look for build file in current directory or build/ subdirectory
    if [[ -f "$cursor_file" ]]; then
        # Found in current directory
        :;
    elif [[ -f "build/build.inf" ]]; then
        cursor_file="build/build.inf";
    elif [[ -f "build.inf" ]]; then
        cursor_file="build.inf";
    else
        trace "No build cursor file found";
        return 1;
    fi
    
    # Extract DEV_SEMVER or DEV_VERS
    version=$(grep "^DEV_SEMVER=" "$cursor_file" 2>/dev/null | head -1 | cut -d'=' -f2);
    if [[ -z "$version" ]]; then
        version=$(grep "^DEV_VERS=" "$cursor_file" 2>/dev/null | head -1 | cut -d'=' -f2);
    fi
    
    if [[ -n "$version" ]]; then
        printf "%s\n" "$version";
        ret=0;
    else
        error "Failed to parse version from cursor file: $cursor_file";
    fi
    
    return "$ret";
}

################################################################################
#
#  __write_cursor_version - Update version in .build file
#
################################################################################
# Arguments:
#   1: new_version (string) - New version to write
# Returns: 0 on success, 1 on failure
# Local Variables: new_version, cursor_file, backup_file, ret

__write_cursor_version() {
    local new_version="$1";
    local cursor_file=".build";
    local backup_file;
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "Version required";
        return 1;
    fi
    
    # Determine cursor file location
    if [[ -f "$cursor_file" ]]; then
        # Update existing file in current directory
        :;
    elif [[ -f "build/build.inf" ]]; then
        cursor_file="build/build.inf";
    elif [[ -f "build.inf" ]]; then
        cursor_file="build.inf";
    else
        # Create new cursor file
        trace "Creating new build cursor file: $cursor_file";
        if ! __print_build_info "$cursor_file"; then
            error "Failed to create build cursor file";
            return 1;
        fi
        ret=0;
    fi
    
    if [[ "$ret" -ne 0 ]] && [[ -f "$cursor_file" ]]; then
        backup_file="${cursor_file}.semv-backup";
        
        # Create backup
        if ! cp "$cursor_file" "$backup_file"; then
            error "Failed to create backup of $cursor_file";
            return 1;
        fi
        
        # Update DEV_SEMVER and DEV_VERS
        sed -i.tmp \
            -e "s/^DEV_SEMVER=.*/DEV_SEMVER=$new_version/" \
            -e "s/^DEV_VERS=.*/DEV_VERS=$new_version/" \
            "$cursor_file";
        
        if [[ $? -eq 0 ]]; then
            trace "Updated $cursor_file version to $new_version";
            rm -f "${cursor_file}.tmp" "$backup_file";
            ret=0;
        else
            error "Failed to update $cursor_file";
            mv "$backup_file" "$cursor_file";
        fi
    fi
    
    return "$ret";
}

# Mark sync-parsers as loaded (load guard pattern)
readonly SEMV_SYNC_PARSERS_LOADED=1;