#
# semv-commands.sh - High-Order Command Functions
# semv-revision: 2.0.0
# BashFX compliant command implementations
#

################################################################################
#
#  Version Bump Commands
#
################################################################################

################################################################################
#
#  do_bump - Create and push new version tag
#
################################################################################
# Arguments:
#   1: force (optional) - Skip confirmations if "0"
# Returns: 0 on success, 1 on failure
# Local Variables: force, latest, new_version, ret

do_bump() {
    local force="${1:-1}";
    local latest;
    local new_version;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi

    # Ensure repository has a semv baseline for friendlier guidance
    if ! require_semv_baseline; then
        return 1;
    fi
    
    # Get current and next versions
    latest=$(do_latest_tag);
    new_version=$(do_next_semver "$force");
    ret=$?;
    
    if [[ "$ret" -eq 0 ]] && [[ -n "$new_version" ]]; then
        trace "Bump: $latest -> $new_version";
        
        if _do_retag "$new_version" "$latest"; then
            okay "Version bumped successfully: $new_version";
            ret=0;
        else
            error "Failed to create version tag";
            ret=1;
        fi
    else
        error "Failed to calculate next version";
    fi
    
    return "$ret";
}

################################################################################
#
#  _do_retag - Internal function to create and push tags
#
################################################################################
# Arguments:
#   1: new_tag (string) - New tag to create
#   2: current_tag (string) - Current tag for comparison
# Returns: 0 on success, 1 on failure
# Local Variables: new_tag, current_tag, note, ret

_do_retag() {
    local new_tag="$1";
    local current_tag="$2";
    local note;
    local ret=1;
    
    if [[ -z "$new_tag" ]]; then
        error "Missing new tag";
        return 1;
    fi
    
    if ! has_semver || ! is_main; then
        error "Can only retag on main branch with existing semver";
        return 1;
    fi
    
    # Check if this is actually a version increase
    if ! do_is_greater "$new_tag" "$current_tag"; then
        error "New version ($new_tag) is not greater than current ($current_tag)";
        return 1;
    fi
    
    # Check for uncommitted changes
    if ! is_not_staged; then
        if __confirm "You have uncommitted changes. Commit them with this tag"; then
            git add --all;
            git commit -m "auto: adding changes for retag @${new_tag}";
        else
            error "Cancelled due to uncommitted changes";
            return 1;
        fi
    fi
    
    # Get tag message
    note=$(__prompt "Tag message" "auto tag bump");
    
    # Create tag
    if __git_tag_create "$new_tag" "$note"; then
        info "Created tag: $new_tag";
        
        # Push tags (only if a remote exists); local tagging still succeeds
        if git remote get-url origin >/dev/null 2>&1; then
            if __git_push_tags "force"; then
                okay "Pushed tags to remote";
                # Push commits if confirmed
                if __confirm "Push commits for $new_tag and main to origin"; then
                    git push origin "$new_tag";
                    git push origin main;
                    okay "Pushed commits to remote";
                fi
                ret=0;
            else
                warn "Failed to push tags to remote; local tag created";
                ret=0;
            fi
        else
            info "No 'origin' remote configured; skipping push";
            ret=0;
        fi
    else
        error "Failed to create tag";
    fi
    
    return "$ret";
}

################################################################################
#
#  Information and Analysis Commands
#
################################################################################

################################################################################
#
#  do_info - Show repository and version status
#
################################################################################
# Returns: 0 on success
# Local Variables: user, branch, main_branch, project, build, remote_build, changes, since, days, semver, next
# Stream Usage: Messages to stderr

do_info() {
    local user;
    local branch;
    local main_branch;
    local project;
    local build;
    local remote_build;
    local changes;
    local since;
    local days;
    local semver;
    local next;
    local msg="";
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    # Gather repository information
    user=$(this_user);
    branch=$(this_branch);
    main_branch=$(which_main);
    project=$(this_project);
    
    if [[ -z "$user" ]]; then
        user="${red}-unset-${x}";
    fi
    
    if has_commits; then
        build=$(__git_build_count);
        remote_build=$(__git_remote_build_count);
        changes=$(__git_status_count);
        since=$(do_since_pretty);
        days=$(do_days_ago);
        
        # Format change count
        if [[ "$changes" -gt 0 ]]; then
            changes="${green}Edits +$changes${x}";
        else
            changes="${grey}none${x}";
        fi
        
        # Format build comparison
        if [[ "$remote_build" -gt "$build" ]]; then
            remote_build="${green}${remote_build}${x}";
        elif [[ "$remote_build" -eq "$build" ]]; then
            # Equal builds - no highlighting
            :;
        else
            build="${green}${build}${x}";
        fi
        
        # Build info message
        msg+="~~ Repository Status ~~\n";
        msg+="${spark} User: [${user}]\n";
        msg+="${spark} Repo: [${project}] [${branch}] [${main_branch}]\n";
        msg+="${spark} Changes: [${changes}]\n";
        msg+="${spark} Build: [${build}:${remote_build}]\n";
        msg+="${spark} Last: [${days} days] ${since}\n";
        
        # Version information
        if has_semver; then
            semver=$(do_latest_semver);
            next=$(do_next_semver 0 2>/dev/null);
            
            if [[ -z "$next" ]]; then
                next="${red}-none-${x}";
            elif do_is_greater "$next" "$semver"; then
                next="${green} -> ${next}${x}";
            elif [[ "$next" == "$semver" ]]; then
                next="<-same-> ${next}";
            fi
            
            msg+="${spark} Version: [${semver} ${next}]";
        else
            msg+="${spark} Version: [${red}-unset-${x}]";
        fi
        
        printf "%b\n" "$msg" >&2;
    else
        warn "Repository: [${user}] [${project}] [${branch}] [${red}no commits${x}]";
    fi
    
    return 0;
}

################################################################################
#
#  do_build_count - Show current build count (commit count + floor)
#
################################################################################
# Returns: 0 on success

do_build_count() {
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    __git_build_count;
    return 0;
}

################################################################################
#
#  do_mark_1 - First-time registration (baseline tag)
#
################################################################################
# Behavior:
# - If semver tags already exist: report current latest and exit 0.
# - If no tags: detect package version(s). If found, create sync tag at that version.
#   Otherwise, default to v0.0.1.
# Returns: 0 on success, 1 on failure

do_mark_1() {
    local project_types;
    local pkg_version="";
    local latest="";

    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi

    # Already initialized?
    if has_semver; then
        latest=$(do_latest_tag);
        okay "Repository already initialized (latest: ${latest})";
        return 0;
    fi

    # Detect project types and find package version baseline (highest)
    if project_types=$(detect_project_type); then
        pkg_version=$(_get_package_version "$project_types" 2>/dev/null || true)
    fi

    if [[ -n "$pkg_version" ]]; then
        info "Initializing from package version: $pkg_version";
        if __create_sync_tag "$pkg_version"; then
            okay "Baseline created at v${pkg_version}";
            return 0;
        else
            error "Failed to create baseline sync tag at v${pkg_version}";
            return 1;
        fi
    else
        info "No package version found; defaulting to v0.0.1";
        if __git_tag_create "v0.0.1" "semv mark1: initial baseline"; then
            okay "Baseline created at v0.0.1";
            return 0;
        else
            error "Failed to create baseline tag v0.0.1";
            return 1;
        fi
    fi
}

################################################################################
#
#  do_pre_commit - Pre-commit validation gate
#
################################################################################
# Returns: 0 if validation passes, 1 if not

do_pre_commit() {
    local ret=0
    if ! is_repo; then
        error "Not in a git repository"
        return 1
    fi

    info "Running pre-commit validation..."
    if do_validate; then
        okay "Pre-commit validation passed"
        ret=0
    else
        error "Pre-commit validation failed"
        warn "Run 'semv drift' and 'semv sync' to resolve version drift"
        ret=1
    fi
    return "$ret"
}

################################################################################
#
#  do_audit - Summarize repository and version state (non-destructive)
#
################################################################################
# Returns: 0 always

do_audit() {
    local types
    local pkg_ver git_ver next_ver

    if ! is_repo; then
        error "Not in a git repository"
        return 1
    fi

    info "SEM V Audit Report"
    if types=$(detect_project_type); then
        info "Detected: ${types}"
        pkg_ver=$(_get_package_version "$types" 2>/dev/null || true)
    else
        warn "No supported project types detected"
    fi
    git_ver=$(_latest_tag 2>/dev/null || true)
    next_ver=$(_calculate_semv_version 2>/dev/null || true)

    printf "\nCurrent versions:\n" >&2
    printf "  Package: %s\n" "${pkg_ver:-none}" >&2
    printf "  Git tag: %s\n" "${git_ver:-none}" >&2
    printf "  Next:    %s\n" "${next_ver:-n/a}" >&2

    # Drift analysis (info only)
    do_drift >/dev/null || true
    return 0
}

################################################################################
#
#  do_latest_remote - Show latest remote semver tag (origin)
#
################################################################################
# Returns: 0 on success, 1 on failure

do_latest_remote() {
    local out latest taglist
    if ! is_repo; then error "Not in a git repository"; return 1; fi
    info "Fetching remote tags..."
    __git_fetch_tags >/dev/null 2>&1 || true
    # Try ls-remote; fallback to local
    if out=$(git ls-remote --tags origin 2>/dev/null); then
        taglist=$(printf "%s\n" "$out" | awk '{print $2}' | sed 's@^refs/tags/@@' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)
        latest=$(printf "%s\n" "$taglist" | tail -1)
        if [[ -n "$latest" ]]; then printf "%s\n" "$latest"; return 0; fi
    fi
    # Fallback to local latest
    latest=$(do_latest_semver 2>/dev/null || true)
    if [[ -n "$latest" ]]; then printf "%s\n" "$latest"; return 0; fi
    return 1
}

################################################################################
#
#  do_remote_compare - Compare latest local vs remote semver tag
#
################################################################################
# Returns: 0 on success (prints comparison), 1 on failure

do_remote_compare() {
    local local latest_remote
    if ! is_repo; then error "Not in a git repository"; return 1; fi
    local=$(do_latest_semver 2>/dev/null || true)
    latest_remote=$(do_latest_remote 2>/dev/null || true)
    if [[ -z "$local" && -z "$latest_remote" ]]; then
        warn "No semver tags locally or remotely"
        return 0
    fi
    printf "Local:  %s\n" "${local:-none}" >&2
    printf "Remote: %s\n" "${latest_remote:-none}" >&2
    return 0
}

################################################################################
#
#  do_rbuild_compare - Compare local vs remote build counts
#
################################################################################
# Returns: 0 always

do_rbuild_compare() {
    local localb remoteb
    if ! is_repo; then error "Not in a git repository"; return 1; fi
    localb=$(__git_build_count)
    remoteb=$(__git_remote_build_count)
    printf "Build(local:remote) %s:%s\n" "$localb" "$remoteb" >&2
    return 0
}

################################################################################
#
#  do_pending - Show pending changes since last tag
#
################################################################################
# Arguments:
#   1: label (optional) - Commit label to filter (default: "any")
# Returns: 0 if changes found, 1 if none
# Local Variables: latest, label, changes, ret

do_pending() {
    local latest;
    local label="${1:-any}";
    local changes;
    local ret=1;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    latest=$(do_latest_tag);
    if [[ -n "$latest" ]]; then
        if [[ "$label" != "any" ]]; then
            changes=$(git log "${latest}"..HEAD --grep="^${label}:" --pretty=format:"%h - %s");
        else
            changes=$(git log "${latest}"..HEAD --pretty=format:"%h - %s");
        fi
        
        if [[ -n "$changes" ]]; then
            warn "Found changes ($label) since $latest:";
            printf "%s\n" "$changes" >&2;
            ret=0;
        else
            okay "No labeled ($label:) commits after $latest";
            ret=1;
        fi
    else
        error "No tags found. Try 'semv new' to initialize";
        ret=1;
    fi
    
    return "$ret";
}

################################################################################
#
#  do_last - Show time since last commit
#
################################################################################
# Returns: 0 on success
# Local Variables: days, since, semver

do_last() {
    local days;
    local since;
    local semver;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    days=$(do_days_ago);
    since=$(do_since_pretty);
    semver=$(do_latest_tag);
    
    if [[ "$days" -lt 7 ]]; then
        okay "Last commit was $since";
    elif [[ "$days" -lt 30 ]]; then
        warn "Last commit was $since";
    else
        error "Last commit was $since";
    fi
    
    return 0;
}

################################################################################
#
#  do_status - Show working directory status
#
################################################################################
# Returns: 0 if changes exist, 1 if clean
# Local Variables: count
# Outputs: Number of changed files to stdout

do_status() {
    local count;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    count=$(__git_status_count);
    printf "%d\n" "$count";
    
    if [[ "$count" -gt 0 ]]; then
        return 0;
    else
        return 1;
    fi
}

################################################################################
#
#  Remote and Tag Management Commands
#
################################################################################

################################################################################
#
#  do_fetch_tags - Fetch tags from remote
#
################################################################################
# Returns: git fetch return code

do_fetch_tags() {
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    __git_fetch_tags;
}

################################################################################
#
#  do_tags - List all git tags
#
################################################################################
# Returns: 0 on success
# Local Variables: tags

do_tags() {
    local tags;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    tags=$(__git_list_tags);
    info "Repository tags:";
    printf "%s\n" "$tags" >&2;
    
    return 0;
}

################################################################################
#
#  Development and Inspection Commands
#
################################################################################

################################################################################
#
#  do_inspect - Show available functions and dispatch mappings
#
################################################################################
# Returns: 0 always

do_inspect() {
    info "Available SEMV functions:";
    func ls "$SEMV_PATH" 2>/dev/null | grep "^do_" | sort >&2;
    
    info "";
    info "Dispatch table commands:";
    info "Version: latest, next, bump";
    info "Analysis: info, pending, changes, since, status";
    info "Build: file, bc, bcr";
    info "Repo: new, can, fetch, tags";
    info "Remote: remote, upstream, rbc";
    info "Sync: get, set, sync, validate, drift";
    info "Workflow: pre-commit, release, audit";
    info "Lifecycle: install, uninstall, reset";
    info "Promotion: promote";
    info "Hooks: hook";
    info "Dev: inspect, labels, auto";
    
    return 0;
}

################################################################################
#
#  do_label_help - Show commit label conventions
#
################################################################################
# Returns: 0 always

do_label_help() {
    local msg="";
    
    msg+="~~ SEMV Commit Labels ~~\n";
    msg+="${spark} ${green}major|breaking|api:${x}   -> Major changes [Major]\n";
    msg+="${spark} ${green}feat|feature|add|minor:${x} -> Features [Minor]\n";
    msg+="${spark} ${green}fix|patch|bug|hotfix|up:${x} -> Fixes/docs [Patch]\n";
    msg+="${spark} ${green}dev:${x}                   -> Development notes [Dev Build]\n";
    
    printf "%b\n" "$msg" >&2;
    return 0;
}

################################################################################
#
#  Placeholder Commands (Future Implementation)
#
################################################################################

################################################################################
#
#  do_auto - Auto mode for external tools
#
################################################################################
# Arguments:
#   1: path (string) - Path to analyze
#   2: command (string) - Command to execute
# Returns: Command-specific return code

do_auto() {
    local action="${1:-sync}";
    shift || true;
    
    trace "Auto mode: $action";
    
    case "$action" in
        sync)
            info "Auto-sync: Running version synchronization";
            do_sync "$@";
            ;;
        validate)
            info "Auto-validate: Running version validation";
            do_validate "$@";
            ;;
        drift)
            info "Auto-drift: Running drift analysis";
            do_drift "$@";
            ;;
        *)
            info "Auto mode (default): Running sync";
            do_sync "$action" "$@";
            ;;
    esac
}

################################################################################
#
#  do_sync - Version synchronization and conflict resolution
#
################################################################################
# Returns: 0 on success, 1 on failure
# Stream Usage: Messages to stderr

################################################################################
#
#  do_since_pretty - Pretty format for time since last commit
#
################################################################################

do_since_pretty() {
    local seconds;
    seconds=$(_seconds_since_last_commit 2>/dev/null);
    if [[ -n "$seconds" ]]; then
        _pretty_duration "$seconds";
    else
        printf "unknown";
    fi
}

################################################################################
#
#  do_days_ago - Days since last commit
#
################################################################################

do_days_ago() {
    local seconds;
    seconds=$(_seconds_since_last_commit 2>/dev/null);
    if [[ -n "$seconds" ]]; then
        printf "%d" $((seconds / 86400));
    else
        printf "0";
    fi
}

################################################################################
#
#  do_sync - Version synchronization and conflict resolution
#
################################################################################
# Returns: 0 on success, 1 on failure
# Stream Usage: Messages to stderr

do_sync() {
    info "Starting version synchronization and conflict resolution...";
    
    if resolve_version_conflicts; then
        okay "Version synchronization completed successfully";
        return 0;
    else
        error "Version synchronization failed";
        return 1;
    fi
}

# Mark commands as loaded (load guard pattern)
readonly SEMV_COMMANDS_LOADED=1;
