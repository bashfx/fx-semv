#
# semv-git-ops.sh - Git Operations and Repository Information
# semv-revision: 2.0.0-dev_1
# BashFX compliant git operations module
#

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
#  which_main - Get main branch name from remote
#
################################################################################
# Returns: 0 on success, 1 if no commits
# Outputs: Main branch name to stdout

which_main() {
    local ret=1;
    
    if has_commits; then
        git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@';
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  Commit Analysis Functions
#
################################################################################

################################################################################
#
#  last_commit - Get timestamp of last commit
#
################################################################################
# Returns: 0 if commits exist, 1 if none
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
#  Tag Operations
#
################################################################################

################################################################################
#
#  __git_list_tags - List all git tags
#
################################################################################
# Returns: 0 on success
# Outputs: All tags to stdout

__git_list_tags() {
    git show-ref --tags | cut -d '/' -f 3-;
}

################################################################################
#
#  __git_latest_tag - Get latest tag by version sort
#
################################################################################
# Returns: 0 if tags exist, 1 if none
# Local Variables: latest
# Outputs: Latest tag to stdout

__git_latest_tag() {
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
#  __git_latest_semver - Get latest semantic version tag
#
################################################################################
# Returns: 0 if semver tags exist, 1 if none
# Local Variables: latest
# Outputs: Latest semver tag to stdout

__git_latest_semver() {
    local latest;
    local ret=1;
    
    if has_semver; then
        latest=$(git tag --list | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1);
        if [[ -n "$latest" ]]; then
            echo "$latest";
            ret=0;
        fi
    fi
    
    return "$ret";
}

################################################################################
#
#  __git_tag_create - Create annotated git tag
#
################################################################################
# Arguments:
#   1: tag (string) - Tag name to create
#   2: message (string) - Tag message
# Returns: 0 on success, 1 on failure
# Local Variables: tag, msg, ret

__git_tag_create() {
    local tag="$1";
    local msg="$2";
    local ret=1;
    
    if [[ -n "$tag" ]] && [[ -n "$msg" ]]; then
        git tag -a "$tag" -m "$msg";
        ret=$?;
    fi
    
    return "$ret";
}

################################################################################
#
#  __git_tag_delete - Delete git tag locally
#
################################################################################
# Arguments:
#   1: tag (string) - Tag name to delete
# Returns: 0 on success, 1 on failure

__git_tag_delete() {
    local tag="$1";
    local ret=1;
    
    if [[ -n "$tag" ]]; then
        if declare -F __tag_delete >/dev/null 2>&1; then
            __tag_delete "$tag";
            ret=$?;
        else
            git tag -d "$tag";
            ret=$?;
        fi
    fi
    
    return "$ret";
}

################################################################################
#
#  __git_push_tags - Push tags to remote
#
################################################################################
# Arguments:
#   1: force (optional) - Use --force if "force"
# Returns: 0 on success, 1 on failure
# Local Variables: force_flag, ret

__git_push_tags() {
    local force_flag="";
    local ret=1;
    
    if [[ "$1" == "force" ]]; then
        force_flag="--force";
    fi
    
    git push --tags $force_flag;
    ret=$?;
    
    return "$ret";
}

################################################################################
#
#  Build Information Functions
#
################################################################################

################################################################################
#
#  __git_build_count - Get commit count for build number
#
################################################################################
# Returns: 0 on success
# Local Variables: count
# Outputs: Build number to stdout

__git_build_count() {
    local count;
    
    count=$(git rev-list HEAD --count);
    count=$((count + SEMV_MIN_BUILD));
    echo "$count";
    return 0;
}

################################################################################
#
#  __git_remote_build_count - Get remote commit count
#
################################################################################
# Returns: 0 on success
# Local Variables: count
# Outputs: Remote build number to stdout

__git_remote_build_count() {
    local branch="";
    local ref="";
    local count_raw
    local count

    # Determine remote default branch using origin/HEAD if available
    branch=$(which_main 2>/dev/null || true)

    # Fallback: parse git remote show origin
    if [[ -z "$branch" ]]; then
        branch=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p' | head -1)
    fi

    # Fallbacks to common names if remote HEAD not discoverable
    if [[ -z "$branch" ]]; then
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            branch="main"
        elif git show-ref --verify --quiet refs/remotes/origin/master; then
            branch="master"
        else
            branch=""
        fi
    fi

    if [[ -n "$branch" ]]; then
        ref="origin/${branch}"
        count_raw=$(git rev-list "$ref" --count 2>/dev/null || echo 0)
    else
        count_raw=0
    fi

    # Normalize numeric and add floor
    count=$(( ${count_raw:-0} + SEMV_MIN_BUILD ))
    echo "$count"
    return 0;
}

################################################################################
#
#  Status and Analysis Functions
#
################################################################################

################################################################################
#
#  __git_status_count - Count changed files
#
################################################################################
# Returns: 0 on success
# Local Variables: count
# Outputs: Number of changed files to stdout

__git_status_count() {
    local count;
    
    count=$(git status --porcelain | wc -l | awk '{print $1}');
    echo "$count";
    return 0;
}

################################################################################
#
#  __git_fetch_tags - Fetch tags from remote
#
################################################################################
# Returns: git fetch return code
# Local Variables: before_fetch, after_fetch, output, ret

__git_fetch_tags() {
    local before_fetch;
    local after_fetch;
    local output;
    local ret;
    
    before_fetch=$(git tag);
    output=$(git fetch --tags 2>&1);
    ret=$?;
    after_fetch=$(git tag);
    
    if [[ "$before_fetch" != "$after_fetch" ]]; then
        okay "New tag changes found.";
    else
        info "No new tags.";
    fi
    
    return "$ret";
}

################################################################################
#
#  _latest_tag - Wrapper for do_latest_tag (compatibility)
#
################################################################################

_latest_tag() {
    do_latest_tag;
}

################################################################################
#
#  _is_git_repo - Check if current directory is a git repository
#
################################################################################

_is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1;
}

# Mark git-ops as loaded (load guard pattern)
readonly SEMV_GIT_OPS_LOADED=1;
