#!/usr/bin/env bash
#
# semv-commands.sh - High-Order Command Functions
# semv-revision: 2.0.0-dev_1
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
        
        # Push tags
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
            error "Failed to push tags";
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
    info "Available functions:";
    declare -F | grep 'do_' | awk '{print $3}' >&2;
    
    info "Dispatch mappings:";
    # This would show the dispatch table if implemented
    info "(Dispatch table inspection not implemented yet)";
    
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
    msg+="${spark} ${green}brk:${x}  -> Breaking changes [Major]\n";
    msg+="${spark} ${green}feat:${x} -> New features [Minor]\n";
    msg+="${spark} ${green}fix:${x}  -> Bug fixes [Patch]\n";
    msg+="${spark} ${green}dev:${x}  -> Development notes [Dev Build]\n";
    
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
    local path="$1";
    local cmd="$2";
    
    # Placeholder for auto mode implementation
    error "Auto mode not implemented yet";
    return 1;
}

# Mark commands as loaded (load guard pattern)
readonly SEMV_COMMANDS_LOADED=1;