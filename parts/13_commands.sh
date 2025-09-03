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
#  status_data - Data-only status producer (machine-readable)
#
################################################################################
# Returns: 0 on success, 1 on failure
# Output (stdout): single-line semicolon-separated key=value pairs
# Keys: user, repo, branch, main_branch, changes, build_local, build_remote,
#       days, since, tags_last, tags_release, version_current, version_next

status_data() {
    local user branch main_branch project
    local build_local build_remote changes days since
    local tags_last tags_release
    local version_current version_next
    local pkg git calc

    if ! is_repo; then
        return 1;
    fi

    # Basics
    user=$(this_user 2>/dev/null || true)
    branch=$(this_branch 2>/dev/null || true)
    main_branch=$(which_main 2>/dev/null || true)
    project=$(this_project 2>/dev/null || true)

    # Metrics
    if has_commits; then
        build_local=$(__git_build_count 2>/dev/null || echo 0)
        build_remote=$(__git_remote_build_count 2>/dev/null || echo 0)
        changes=$(__git_status_count 2>/dev/null || echo 0)
        since=$(do_since_pretty 2>/dev/null || echo unknown)
        days=$(do_days_ago 2>/dev/null || echo 0)
    else
        build_local=0; build_remote=0; changes=0; since=unknown; days=0;
    fi

    # Tags
    tags_last=$(do_latest_semver 2>/dev/null || true)
    if git rev-parse -q --verify refs/tags/release >/dev/null 2>&1; then
        local rel_commit rel_ver rel_short
        rel_commit=$(git rev-parse release 2>/dev/null || true)
        rel_ver=$(git tag --points-at "$rel_commit" | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
        rel_short=$(git rev-parse --short "$rel_commit" 2>/dev/null || true)
        if [[ -n "$rel_ver" ]]; then
            tags_release="$rel_ver"
        else
            tags_release=""
        fi
    else
        tags_release=""
    fi

    # Versions
    if has_semver; then
        version_current=$(do_latest_semver 2>/dev/null || true)
        version_next=$(do_next_semver 0 2>/dev/null || true)
    else
        version_current=""
        version_next=""
    fi

    # Provide consolidated fields for consumers (avoid multiple data sources)
    # pkg: highest package file version if any
    local project_types
    if project_types=$(detect_project_type 2>/dev/null); then
        pkg=$(_get_package_version "$project_types" 2>/dev/null || true)
    fi
    git="$tags_last"
    calc="$version_next"

    # Emit semicolon-separated kv stream (single line)
    printf "user=%s;repo=%s;branch=%s;main_branch=%s;changes=%s;build_local=%s;build_remote=%s;days=%s;since=%s;tags_last=%s;tags_release=%s;version_current=%s;version_next=%s;pkg=%s;git=%s;calc=%s\n" \
        "$user" "$project" "$branch" "$main_branch" "$changes" "$build_local" "$build_remote" "$days" "$since" "$tags_last" "$tags_release" "$version_current" "$version_next" "$pkg" "$git" "$calc"
    return 0
}

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
    local changes_num;
    local since;
    local days;
    local semver;
    local next;
    local latest_tag="";
    local release_desc="";
    local msg="";
    
    # Data view passthrough
    if [[ "$(get_view_mode)" == "data" ]]; then
        status_data;
        return $?
    fi

    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    # Gather base info via status_data for consistency
    local kd i key val data
    data=$(status_data 2>/dev/null || true)
    # Parse semicolon-separated kv pairs
    IFS=';' read -ra kd <<< "$data"
    for i in "${kd[@]}"; do
        key="${i%%=*}"; val="${i#*=}"
        case "$key" in
            user) user="$val";;
            repo) project="$val";;
            branch) branch="$val";;
            main_branch) main_branch="$val";;
            changes) changes_num="$val";;
            build_local) build="$val";;
            build_remote) remote_build="$val";;
            days) days="$val";;
            since) since="$val";;
            tags_last) latest_tag="$val";;
            tags_release) release_desc="$val";;
            version_current) semver="$val";;
            version_next) next="$val";;
        esac
    done
    
    if [[ -z "$user" ]]; then
        user="${red}-unset-${x}";
    fi
    
    if has_commits; then
        # already populated from data; ensure defaults
        build="${build:-0}"; remote_build="${remote_build:-0}";
        changes_num="${changes_num:-0}"; since="${since:-unknown}"; days="${days:-0}";
        
        # Format change count
        if [[ "$changes_num" -gt 0 ]]; then
            changes="${green}${changes_num}${x} file(s)";
        else
            changes="${grey}0${x} file(s)";
        fi
        
        # Format build comparison
        if [[ "$remote_build" -gt "$build" ]]; then
            remote_build="${green}${remote_build}${x}";  # remote ahead
        elif [[ "$remote_build" -eq "$build" ]]; then
            :; # equal
        else
            build="${green}${build}${x}";                # local ahead
        fi
        
        # latest_tag and release_desc already populated via status_data

        # Build info message (emoji + 4-letter codes); colorize bracketed data fields
        msg+="~~ Repository Status ~~\n";
        msg+="👷 USER: [${grey}${user}${x}]\n";
        msg+="📦 REPO: [${grey}${project}${x}] [${grey}${branch}${x}] [${grey}${main_branch}${x}]\n";
        # Changes: color whole bracket (green when >0, grey when 0)
        local chng_disp chng_color
        chng_disp="${changes_num} file(s)"
        if [[ "$changes_num" -gt 0 ]]; then chng_color="$green"; else chng_color="$grey"; fi
        msg+="✏️ CHNG: [${chng_color}${chng_disp}${x}]\n";
        # Build: color numbers by relation, keep bracket context orange
        local col_local col_remote
        if [[ "$build" -gt "$remote_build" ]]; then
            col_local="$green"; col_remote="$red";
        elif [[ "$build" -lt "$remote_build" ]]; then
            col_local="$red"; col_remote="$green";
        else
            col_local="$blue"; col_remote="$blue";
        fi
        msg+="🔧 BULD: [${grey}local=${col_local}${build}${x}${grey} remote=${col_remote}${remote_build}${x}]\n";
        # Last: color whole bracket in orange for readability; pretty string follows as-is
        msg+="⏱️ LAST: [${grey}${days} days${x}] ${since}\n";
        # Tags on one line: last [ ] release [ ] with colored contents
        local ltag_disp rtag_disp
        if [[ -n "$latest_tag" ]]; then
            ltag_disp="${grey}${latest_tag}${x}"
        else
            ltag_disp="${grey}-none-${x}"
        fi
        if [[ -n "$release_desc" ]]; then
            rtag_disp="${grey}${release_desc}${x}"
        else
            rtag_disp="${grey}-none-${x}"
        fi
        msg+="🏷️ TAGS: last [${ltag_disp}] release [${rtag_disp}]\n";
        
        # Version information (color current in grey; next colored by relation)
        if has_semver; then
            local next_raw next_disp
            next_raw="${next}"  # from status_data
            if [[ -z "$next_raw" ]]; then
                next_disp="${red}-none-${x}"
            elif [[ "$next_raw" == "$semver" ]]; then
                next_disp="${blue}${next_raw}${x}"  # same
            elif do_is_greater "$next_raw" "$semver"; then
                next_disp="${green}${next_raw}${x}" # ahead
            else
                next_disp="${orange}${next_raw}${x}" # fallback
            fi
            msg+="🔎 VERS: [${grey}${semver}${x} -> ${next_disp}]";
        else
            msg+="🔎 VERS: [${red}-unset-${x}]";
        fi
        
        # Render via view layer (boxy if available), support --view=data passthrough
        view_status "$msg";
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
    local final_result

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

    # Build final result
    final_result=$(printf "\nCurrent versions:\n  Package: %s\n  Git tag: %s\n  Next:    %s\n" "${pkg_ver:-none}" "${git_ver:-none}" "${next_ver:-n/a}")

    # Output with optional boxy wrapper
    if [[ "$SEMV_USE_BOXY" == "1" ]] && command_exists boxy; then
        echo "$final_result" | boxy --theme info --title "🔍 Audit Report"
    else
        echo "$final_result" >&2
    fi

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
    local final_result;
    
    if ! is_repo; then
        error "Not in a git repository";
        return 1;
    fi
    
    count=$(__git_status_count);
    final_result="$count"

    # Human-readable summary to stderr to avoid confusion with build count
    if [[ "$count" -eq 0 ]]; then
        okay "Working tree is clean"
    else
        warn "Working tree has $count changed file(s)"
    fi

    # Machine-readable count on stdout (kept for scripts)
    if [[ "$SEMV_USE_BOXY" == "1" ]] && command_exists boxy; then
        echo "$final_result" | boxy --theme info --title "📊 Git Status Count"
    else
        echo "$final_result"
    fi

    # Exit code: 0 if changes exist, 1 if clean (legacy behavior)
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
    info "Analysis: info, status, gs, pending, changes, since";
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
#  do_can_semver - Check if repository is ready for semantic versioning
#
################################################################################
# Returns: 0 if ready, 1 if not ready

do_can_semver() {
    local ret=0;
    local issues=0;
    
    info "Checking semver readiness...";
    
    # Check 1: Is this a git repository?
    if ! _is_git_repo; then
        error "Not in a git repository";
        ((issues++));
    else
        okay "✓ Git repository detected";
    fi
    
    # Check 2: Does it have any commits?
    if ! git rev-parse HEAD >/dev/null 2>&1; then
        error "No commits found";
        ((issues++));
    else
        okay "✓ Repository has commits";
    fi
    
    # Check 3: Does it have semver tags?
    if has_semver; then
        okay "✓ Semver tags found";
    else
        warn "No semver tags found (use 'semv new' to initialize)";
    fi
    
    # Check 4: Are there uncommitted changes?
    if is_not_staged; then
        okay "✓ Working tree is clean";
    else
        warn "Uncommitted changes detected";
        info "Consider committing before version operations";
    fi
    
    # Check 5: Can we detect project type?
    if detect_project_type >/dev/null 2>&1; then
        okay "✓ Project type detected";
    else
        warn "No supported package files found";
        info "Semv will use git tags as authority";
    fi
    
    # Report results
    if [[ "$issues" -eq 0 ]]; then
        okay "Repository is ready for semantic versioning";
        ret=0;
    else
        error "Repository is not ready for semantic versioning";
        info "Fix the issues above and try again";
        ret=1;
    fi
    
    return "$ret";
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
    # Optional: source file to compare/sync against
    local source_file="${1:-}";

    info "Starting version synchronization and conflict resolution...";

    if resolve_version_conflicts "$source_file"; then
        okay "Version synchronization completed successfully";
        return 0;
    else
        error "Version synchronization failed";
        return 1;
    fi
}

# Mark commands as loaded (load guard pattern)
readonly SEMV_COMMANDS_LOADED=1;
