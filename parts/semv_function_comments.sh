#!/usr/bin/env bash
#
# semv-function-comments.sh - Function Comment Bar Examples
# semv-revision: 2.0.0-dev_1
# Demonstrates proper BashFX function commenting standards
#

################################################################################
#
#  split_vers - Parse semantic version string
#
################################################################################
# Arguments:
#   1: vers_str (string) - Version string to parse (e.g., "v1.2.3-dev_5")
# Returns: 0 on success, 1 on invalid format
# Local Variables: vers_str, major, minor, patch, extra
# Outputs: Space-separated version components to stdout

split_vers() {
    local vers_str="$1";
    local ret=1;
    
    if [[ $vers_str =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$ ]]; then
        major=${BASH_REMATCH[1]};
        minor=${BASH_REMATCH[2]};
        patch=${BASH_REMATCH[3]};
        extra=${BASH_REMATCH[4]};
        echo "$major $minor $patch $extra";
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  since_last - Count commit messages by label since tag
#
################################################################################
# Arguments:
#   1: tag (string) - Git tag to count from
#   2: label (string) - Commit message prefix to count
# Returns: 0 on success, 1 if not in repo
# Local Variables: tag, label, count
# Outputs: Number of matching commits to stdout

since_last() {
    local tag="$1";
    local label="$2";
    local count;
    local ret=1;

    if is_repo; then
        count=$(git log --pretty=format:"%s" "${tag}"..HEAD | grep -cE "^${label}:");
        echo "$count";
        trace "[$count] [$label] changes since [$tag]";
        ret=0;
    else
        error "Error. current dir not a git repo.";
    fi
    
    return "$ret";
}

################################################################################
#
#  Repository State Checks
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
# Local Variables: b (branch name)

is_main() {
    local b;
    local ret=1;
    
    b=$(this_branch);
    if [[ -n "$b" ]] && [[ "$b" == "main" || "$b" == "master" ]]; then
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
#  Repository Information Functions
#
################################################################################

################################################################################
#
#  this_branch - Get current branch name
#
################################################################################
# Returns: 0 on success
# Outputs: Branch name to stdout

this_branch() {
    git branch --show-current;
}

################################################################################
#
#  this_user - Get git user name
#
################################################################################
# Returns: 0 on success
# Outputs: Git user name (spaces removed) to stdout

this_user() {
    git config user.name | tr -d ' ';
}

################################################################################
#
#  this_project - Get project name from git root
#
################################################################################
# Returns: 0 on success
# Outputs: Project directory name to stdout

this_project() {
    basename "$(git rev-parse --show-toplevel)";
}

################################################################################
#
#  Version Analysis Functions
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
        latest=$(git tag | sort -V | tail -n1);
        if [[ -n "$latest" ]]; then
            echo "$latest";
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
        latest=$(git tag --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1);
        if [[ -n "$latest" ]]; then
            echo "$latest";
            ret=0;
        fi
    else
        error "Error. No semver tags found.";
    fi
    
    return "$ret";
}

################################################################################
#
#  Build Information Functions
#
################################################################################

################################################################################
#
#  do_build_count - Get current build number
#
################################################################################
# Returns: 0 on success
# Local Variables: count
# Outputs: Build number to stdout

do_build_count() {
    local count;
    
    count=$(git rev-list HEAD --count);
    count=$((count + SEMV_MIN_BUILD));
    echo "$count";
    return 0;
}

################################################################################
#
#  last_commit - Get timestamp of last commit
#
################################################################################
# Returns: 0 if commits exist, 1 if none
# Local Variables: none
# Outputs: Unix timestamp to stdout, "0" if no commits

last_commit() {
    local ret=1;
    
    if has_commits; then
        if git rev-parse HEAD >/dev/null 2>&1; then
            git show -s --format=%ct HEAD;
            ret=0;
        fi
    fi
    
    if [[ "$ret" -eq 1 ]]; then
        echo "0";
    fi
    
    return "$ret";
}