#
# semv-guards.sh - Validation and State Check Functions
# semv-revision: 2.0.0-dev_1
# BashFX compliant guard functions
#

################################################################################
#
#  Repository State Guards
#
################################################################################

################################################################################
#
#  is_repo - Check if current directory is a git repository
#
################################################################################
# Returns: 0 if git repo, 1 if not
# Local Variables: none

is_repo() {
    git rev-parse --is-inside-work-tree > /dev/null 2>&1;
}

################################################################################
#
#  is_main - Check if current branch is main/master
#
################################################################################
# Returns: 0 if on main/master branch, 1 if not
# Local Variables: branch, ret

is_main() {
    local branch;
    local ret=1;
    
    branch=$(this_branch);
    if [[ -n "$branch" ]] && [[ "$branch" == "main" || "$branch" == "master" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  has_commits - Check if repository has any commits
#
################################################################################
# Returns: 0 if commits exist, 1 if not

has_commits() {
    local ret=1;
    
    if is_repo && git rev-parse HEAD > /dev/null 2>&1; then
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  has_semver - Check if repository has semantic version tags
#
################################################################################
# Returns: 0 if semver tags exist, 1 if not

has_semver() {
    git tag --list | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+$';
}

################################################################################
#
#  is_not_staged - Check if working directory is clean
#
################################################################################
# Returns: 0 if clean, 1 if changes staged

is_not_staged() {
    git diff --exit-code > /dev/null 2>&1;
}

################################################################################
#
#  Development Mode Guards
#
################################################################################

################################################################################
#
#  is_dev - Check if development mode is enabled
#
################################################################################
# Returns: 0 if dev mode active, 1 if not

is_dev() {
    [[ "$opt_dev" -eq 0 ]] || [[ "${DEV_MODE:-}" == "1" ]];
}

################################################################################
#
#  is_quiet - Check if quiet mode is enabled
#
################################################################################
# Returns: 0 if quiet mode active, 1 if not

is_quiet() {
    [[ "$opt_quiet" -eq 0 ]] || [[ "${QUIET_MODE:-}" == "1" ]];
}

################################################################################
#
#  is_force - Check if force mode is enabled
#
################################################################################
# Returns: 0 if force mode active, 1 if not

is_force() {
    [[ "$opt_force" -eq 0 ]];
}

################################################################################
#
#  Utility Guards
#
################################################################################

################################################################################
#
#  command_exists - Check if command is available
#
################################################################################
# Arguments:
#   1: cmd (string) - Command name to check
# Returns: 0 if command exists, 1 if not

command_exists() {
    local cmd="$1";
    type "$cmd" &> /dev/null;
}

################################################################################
#
#  function_exists - Check if function is defined
#
################################################################################
# Arguments:
#   1: func (string) - Function name to check
# Returns: 0 if function exists, 1 if not

function_exists() {
    local func="$1";
    [[ -n "$func" ]] && declare -F "$func" >/dev/null;
}

################################################################################
#
#  is_empty - Check if variable is empty or unset
#
################################################################################
# Arguments:
#   1: var (string) - Variable to check
# Returns: 0 if empty/unset, 1 if has value

is_empty() {
    local var="$1";
    [[ -z "$var" ]];
}

################################################################################
#
#  is_valid_semver - Check if string is valid semantic version
#
################################################################################
# Arguments:
#   1: version (string) - Version string to validate
# Returns: 0 if valid semver, 1 if not
# Local Variables: version

is_valid_semver() {
    local version="$1";
    [[ "$version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]];
}

################################################################################
#
#  File System Guards
#
################################################################################

################################################################################
#
#  is_file - Check if path is a readable file
#
################################################################################
# Arguments:
#   1: path (string) - File path to check
# Returns: 0 if readable file, 1 if not

is_file() {
    local path="$1";
    [[ -f "$path" && -r "$path" ]];
}

################################################################################
#
#  is_dir - Check if path is a directory
#
################################################################################
# Arguments:
#   1: path (string) - Directory path to check
# Returns: 0 if directory exists, 1 if not

is_dir() {
    local path="$1";
    [[ -d "$path" ]];
}

################################################################################
#
#  is_writable - Check if path is writable
#
################################################################################
# Arguments:
#   1: path (string) - Path to check
# Returns: 0 if writable, 1 if not

is_writable() {
    local path="$1";
    [[ -w "$path" ]];
}

# Mark guards as loaded (load guard pattern)
readonly SEMV_GUARDS_LOADED=1;