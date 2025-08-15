#!/usr/bin/env bash
#
# semv-version.sh - Version Parsing and Comparison Logic
# semv-revision: 2.0.0-dev_1
# BashFX compliant version handling with proper stream usage
#

################################################################################
#
#  Version Parsing Functions
#
################################################################################

################################################################################
#
#  split_vers - Parse semantic version string
#
################################################################################
# Arguments:
#   1: vers_str (string) - Version string to parse (e.g., "v1.2.3-dev_5")
# Returns: 0 on success, 1 on invalid format
# Local Variables: vers_str, ret
# Outputs: Space-separated version components to stdout
# Side Effects: Sets global vars major, minor, patch, extra

split_vers() {
    local vers_str="$1";
    local ret=1;
    
    if [[ -z "$vers_str" ]]; then
        return 1;
    fi
    
    if [[ $vers_str =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; then
        major=${BASH_REMATCH[1]};
        minor=${BASH_REMATCH[2]};
        patch=${BASH_REMATCH[3]};
        extra=${BASH_REMATCH[4]};
        printf "%s %s %s %s\n" "$major" "$minor" "$patch" "$extra";
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  _validate_version_format - Validate version string format
#
################################################################################
# Arguments:
#   1: version (string) - Version to validate
# Returns: 0 if valid, 1 if invalid
# Local Variables: version
# Stream Usage: No output (validation only)

_validate_version_format() {
    local version="$1";
    [[ "$version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]];
}

################################################################################
#
#  Version Comparison Functions  
#
################################################################################

################################################################################
#
#  do_compare_versions - Compare two semantic versions
#
################################################################################
# Arguments:
#   1: version1 (string) - First version
#   2: operator (string) - Comparison operator (>, <, =, >=, <=, !=)
#   3: version2 (string) - Second version
# Returns: 0 if comparison true, 1 if false
# Local Variables: v1, op, v2, result
# Stream Usage: Messages to stderr, result to stdout

do_compare_versions() {
    local v1="$1";
    local op="$2"; 
    local v2="$3";
    local result;
    local ret=1;
    
    if [[ -z "$v1" ]] || [[ -z "$v2" ]] || [[ -z "$op" ]]; then
        error "Usage: do_compare_versions <version1> <operator> <version2>";
        return 1;
    fi
    
    # Validate version formats
    if ! _validate_version_format "$v1"; then
        error "Invalid version format: $v1";
        return 1;
    fi
    
    if ! _validate_version_format "$v2"; then
        error "Invalid version format: $v2";
        return 1;
    fi
    
    # Easy case: versions are identical
    if [[ "$v1" == "$v2" ]]; then
        case "$op" in
            '='|'=='|'>='|'<=') 
                printf "true\n";
                ret=0;
                ;;
            *) 
                printf "false\n";
                ret=1;
                ;;
        esac
        return "$ret";
    fi

    # Split versions into arrays using '.' as delimiter
    local OLD_IFS="$IFS";
    IFS='.';
    local -a ver1=($v1) ver2=($v2);
    IFS="$OLD_IFS";

    # Remove 'v' prefix if present
    ver1[0]=${ver1[0]#v};
    ver2[0]=${ver2[0]#v};

    # Find the longest version array to iterate through
    local i;
    local len1=${#ver1[@]};
    local len2=${#ver2[@]};
    local max_len=$(( len1 > len2 ? len1 : len2 ));

    # Compare each component numerically
    for ((i = 0; i < max_len; i++)); do
        # Pad missing components with 0
        local c1=${ver1[i]:-0};
        local c2=${ver2[i]:-0};
        
        # Remove any non-numeric suffixes for comparison
        c1=${c1%%-*};
        c2=${c2%%-*};

        if (( c1 > c2 )); then
            case "$op" in 
                '>'|'>='|'!=') 
                    printf "true\n";
                    ret=0;
                    ;;
                *) 
                    printf "false\n";
                    ret=1;
                    ;;
            esac
            return "$ret";
        fi
        
        if (( c1 < c2 )); then
            case "$op" in 
                '<'|'<='|'!=') 
                    printf "true\n";
                    ret=0;
                    ;;
                *) 
                    printf "false\n";
                    ret=1;
                    ;;
            esac
            return "$ret";
        fi
    done

    # If we get here, they are equal component-by-component
    case "$op" in 
        '='|'=='|'>='|'<=') 
            printf "true\n";
            ret=0;
            ;;
        *) 
            printf "false\n";
            ret=1;
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  do_is_greater - Check if version B > version A
#
################################################################################
# Arguments:
#   1: version_b (string) - Version to test
#   2: version_a (string) - Version to compare against
# Returns: 0 if B > A, 1 otherwise
# Local Variables: result
# Stream Usage: Messages to stderr, no stdout

do_is_greater() {
    local version_b="$1";
    local version_a="$2";
    local result;
    local ret=1;
    
    if [[ -z "$version_a" ]] || [[ -z "$version_b" ]]; then
        error "Invalid comparison - missing version";
        return 1;
    fi
    
    trace "$version_b > $version_a ?";

    # Use comparison function
    result=$(do_compare_versions "$version_b" ">" "$version_a");
    if [[ "$result" == "true" ]]; then
        trace "$version_b > $version_a ✓";
        ret=0;
    else
        trace "$version_b <= $version_a ✗";
        ret=1;
    fi
    
    return "$ret";
}

################################################################################
#
#  Version Display Functions
#
################################################################################

################################################################################
#
#  do_test_semver - Test and display version parsing
#
################################################################################
# Arguments:
#   1: version (string) - Version to test
# Returns: 0 if valid, 1 if invalid
# Local Variables: version, parts, ret
# Stream Usage: Messages to stderr, parsed components to stdout

do_test_semver() {
    local version="$1";
    local parts;
    local ret=1;
    
    if [[ -z "$version" ]]; then
        error "Usage: do_test_semver <version>";
        return 1;
    fi
    
    info "Testing version format: $version";
    
    parts=$(split_vers "$version");
    ret=$?;
    
    if [[ "$ret" -eq 0 ]]; then
        local -a components=($parts);
        okay "Valid semantic version format";
        info "Major: ${components[0]}";
        info "Minor: ${components[1]}";  
        info "Patch: ${components[2]}";
        if [[ -n "${components[3]}" ]]; then
            info "Extra: ${components[3]}";
        fi
        printf "%s\n" "$parts";
    else
        error "Invalid semantic version format";
        error "Expected format: v1.2.3 or v1.2.3-suffix";
    fi
    
    return "$ret";
}

# Mark version as loaded (load guard pattern)
readonly SEMV_VERSION_LOADED=1;