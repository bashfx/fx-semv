#
# 14_hooks.sh - Hook System and Tag Management
# semv-revision: 2.0.0  
# Part of SEMV - Semantic Version Manager
#

################################################################################
#
#  Auto-Retagging System
#
################################################################################

################################################################################
#
#  Tag Helpers
#
################################################################################

__tag_delete() {
    local tag="$1"
    git tag -d "$tag" 2>/dev/null && trace "Removed existing '$tag' tag" || true
}

__retag_to() {
    local tag="$1"; shift
    local version="$1"; shift
    local msg="$1"; shift || true
    local obj
    obj=$(git rev-list -n 1 "$version" 2>/dev/null) || obj=
    if [[ -z "$obj" ]]; then
        warn "Version not found for retag: $version"
        return 1
    fi
    __tag_delete "$tag"
    if git tag -a "$tag" -m "$msg" "$obj"; then
        okay "Retagged '$tag' → $version"
        return 0
    fi
    error "Failed to retag '$tag' to $version"
    return 1
}

################################################################################
#
#  do_retag - Auto-retag special tags based on version state
#
################################################################################
# Arguments:
#   1: new_version - Version being tagged (e.g., v1.2.3 or v1.2.3-dev_5)
#   2: previous_version - Previous version tag
# Returns: 0 on success, 1 on failure
# Local Variables: new_version, prev_version, tag_type, ret
# Stream Usage: Messages to stderr

do_retag() {
    local new_version="$1";
    local prev_version="$2";
    local tag_type;
    local ret=1;
    
    if [[ -z "$new_version" ]]; then
        error "New version required for retagging";
        return 1;
    fi
    
    trace "Auto-retagging analysis: $new_version";
    
    # Determine version type and retag accordingly
    if [[ "$new_version" =~ -dev_ ]]; then
        tag_type="dev";
        __retag_dev "$new_version";
    elif [[ "$new_version" =~ -beta ]]; then
        tag_type="beta";
        __retag_beta "$new_version";
    elif [[ "$new_version" =~ -alpha ]]; then
        tag_type="alpha";  
        __retag_alpha "$new_version";
    else
        # Stable release
        tag_type="stable";
        __retag_stable "$new_version" "$prev_version";
    fi
    
    trace "Completed $tag_type retagging for $new_version";
    ret=0;
    return "$ret";
}

################################################################################
#
#  __retag_dev - Retag 'dev' to point to current development version
#
################################################################################
# Arguments:
#   1: dev_version - Version with dev suffix (e.g., v1.2.3-dev_5)
# Returns: 0 on success, 1 on failure

__retag_dev() {
    local dev_version="$1";
    
    info "Retagging 'dev' to point to: $dev_version";
    
    __retag_to dev "$dev_version" "semv auto-retag: current development version"
}

################################################################################
#
#  __retag_beta - Retag 'latest-dev' when exiting dev mode
#
################################################################################
# Arguments:
#   1: beta_version - Version with beta characteristics
# Returns: 0 on success, 1 on failure

__retag_beta() {
    local beta_version="$1";
    
    info "Retagging 'latest-dev' to point to: $beta_version (exited dev mode)";
    
    # Remove dev tag (no longer in dev mode)
    if git tag -d "dev" 2>/dev/null; then
        info "Removed 'dev' tag (exited dev mode)";
    fi
    
    __retag_to latest-dev "$beta_version" "semv auto-retag: latest development version"
}

################################################################################
#
#  __retag_alpha - Handle alpha version retagging
#
################################################################################
# Arguments:
#   1: alpha_version - Alpha version
# Returns: 0 on success, 1 on failure

__retag_alpha() {
    local alpha_version="$1";
    
    # Alpha versions don't auto-retag for now
    trace "Alpha version detected: $alpha_version (no auto-retag)";
    return 0;
}

################################################################################
#
#  __retag_stable - Retag stable release tags
#
################################################################################  
# Arguments:
#   1: stable_version - Stable version (e.g., v1.2.3)
#   2: prev_version - Previous version for history
# Returns: 0 on success, 1 on failure

__retag_stable() {
    local stable_version="$1";
    local prev_version="$2";
    
    info "Processing stable release: $stable_version";
    
    # Create versioned stable snapshot
    local stable_snapshot="${stable_version}-stable";
    if __retag_to "$stable_snapshot" "$stable_version" "semv stable snapshot: reversion point"; then
        okay "Created stable snapshot: $stable_snapshot";
    else
        warn "Failed to create stable snapshot tag";
    fi
    
    # Remove dev tags (no longer needed)
    if git tag -d "dev" 2>/dev/null; then
        trace "Removed 'dev' tag (stable release)";
    fi
    
    if git tag -d "latest-dev" 2>/dev/null; then
        trace "Removed 'latest-dev' tag (stable release)";
    fi
    
    # Force-retag latest to current stable version
    if ! __retag_to latest "$stable_version" "semv auto-retag: latest stable version"; then
        return 1
    fi
    
    return 0;
}

################################################################################
#
#  Manual Tag Promotion System
#
################################################################################

################################################################################
#
#  do_promote - Promote version through release channels
#
################################################################################
# Arguments:
#   1: target_channel - Channel to promote to (beta, stable, release)
#   2: version - Optional specific version to promote
# Returns: 0 on success, 1 on failure

do_promote() {
    local target_channel="$1";
    local version="${2:-}";
    local current_version;
    local ret=1;
    
    if ! require_semv_baseline; then
        return 1
    fi
    
    if [[ -z "$version" ]]; then
        current_version=$(_latest_tag);
        if [[ -z "$current_version" ]]; then
            error "No version to promote and none specified";
            return 1;
        fi
        version="$current_version";
    fi
    
    case "$target_channel" in
        beta)
            do_promote_to_beta "$version";
            ret=$?;
            ;;
        stable)
            do_promote_to_stable "$version";
            ret=$?;
            ;;
        release)
            do_promote_to_release "$version";
            ret=$?;
            ;;
        *)
            error "Unknown promotion channel: $target_channel";
            info "Supported: beta, stable, release";
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  do_promote_to_beta - Promote dev version to beta
#
################################################################################
# Arguments:
#   1: dev_version - Version to promote from dev
# Returns: 0 on success, 1 on failure

do_promote_to_beta() {
    local dev_version="$1";
    local base_version;
    local beta_version;
    
    # Extract base version (remove dev suffix)
    base_version=$(echo "$dev_version" | sed 's/-dev_.*//')
    beta_version="${base_version}-beta";
    
    info "Promoting $dev_version to beta channel";
    
    # Confirm promotion
    if [[ "$opt_auto" -ne 0 ]]; then
        if ! __confirm "Promote $dev_version to $beta_version"; then
            error "Beta promotion cancelled";
            return 1;
        fi
    fi
    
    # Create beta tag at the resolved dev commit (not implicit HEAD)
    if __retag_to "$beta_version" "$dev_version" "semv promotion: $dev_version → beta"; then
        okay "Created beta version: $beta_version";
        __retag_beta "$beta_version";
        return 0;
    else
        error "Failed to create beta tag: $beta_version";
        return 1;
    fi
}

################################################################################
#
#  do_promote_to_stable - Promote beta/dev version to stable
#
################################################################################
# Arguments:
#   1: source_version - Version to promote to stable
# Returns: 0 on success, 1 on failure

do_promote_to_stable() {
    local source_version="$1";
    local base_version;
    local stable_version;
    
    # Extract base version (remove any suffix)
    base_version=$(echo "$source_version" | sed 's/-[a-z].*//');
    stable_version="$base_version";
    
    info "Promoting $source_version to stable release";
    
    # Confirm promotion with ceremony
    warn "STABLE PROMOTION CEREMONY";
    info "Source: $source_version";  
    info "Target: $stable_version";
    info "This will create stable snapshot and retag 'latest'";
    
    if [[ "$opt_auto" -ne 0 ]]; then
        if ! __confirm "Confirm stable promotion"; then
            error "Stable promotion cancelled";
            return 1;
        fi
    fi
    
    # Create/retag stable version at the resolved commit (not implicit HEAD)
    if __retag_to "$stable_version" "$source_version" "semv promotion: $source_version → stable"; then
        okay "Created stable version: $stable_version";
        __retag_stable "$stable_version" "$source_version";
        return 0;
    else
        error "Failed to create stable tag: $stable_version";
        return 1;
    fi
}

################################################################################
#
#  do_promote_to_release - Promote stable version to public release
#
################################################################################
# Arguments:
#   1: stable_version - Stable version to promote to release
# Returns: 0 on success, 1 on failure

do_promote_to_release() {
    local stable_version="$1";
    
    info "Promoting $stable_version to public release";
    
    # Check if version is actually stable
    if [[ "$stable_version" =~ -dev_|–beta|–alpha ]]; then
        warn "Promoting non-stable version to release: $stable_version";
        if [[ "$opt_auto" -ne 0 ]]; then
            if ! __confirm "Continue with non-stable release promotion"; then
                error "Release promotion cancelled";
                return 1;
            fi
        fi
    fi
    
    # Ceremonious release confirmation
    warn "PUBLIC RELEASE CEREMONY";
    info "Version: $stable_version";
    info "This will retag 'release' for public visibility";
    
    if [[ "$opt_auto" -ne 0 ]]; then
        if ! __confirm "CONFIRM PUBLIC RELEASE"; then
            error "Public release cancelled";
            return 1;
        fi
    fi
    
    # Force-retag release at the resolved commit (not implicit HEAD)
    if __retag_to "release" "$stable_version" "semv promotion: $stable_version → public release"; then
        okay "Promoted to public release: $stable_version";
        return 0;
    else
        error "Failed to retag 'release' to $stable_version";
        return 1;
    fi
}

################################################################################
#
#  Hook Management System
#
################################################################################

################################################################################
#
#  do_hook - Hook management command dispatcher
#
################################################################################
# Arguments:
#   1: hook_type - Type of hook (major, minor, patch, dev)
#   2: action - Action to perform (show, set, stub, remove)
#   3: command - Hook command (for set action)
# Returns: 0 on success, 1 on failure

do_hook() {
    local hook_type="$1";
    local action="${2:-show}";
    local command="$3";
    local ret=1;
    
    case "$hook_type" in
        major|minor|patch|dev)
            case "$action" in
                show|"")
                    show_hook "$hook_type";
                    ret=$?;
                    ;;
                set)
                    if [[ -n "$command" ]]; then
                        set_hook "$hook_type" "$command";
                        ret=$?;
                    else
                        error "Command required for hook set";
                        info "Usage: semv hook $hook_type set \"./my-script.sh\"";
                    fi
                    ;;
                stub)
                    create_hook_stub "$hook_type";
                    ret=$?;
                    ;;
                remove|rm)
                    remove_hook "$hook_type";
                    ret=$?;
                    ;;
                *)
                    error "Unknown hook action: $action";
                    info "Supported: show, set, stub, remove";
                    ;;
            esac
            ;;
        *)
            error "Unknown hook type: $hook_type";
            info "Supported: major, minor, patch, dev";
            ;;
    esac
    
    return "$ret";
}

################################################################################
#
#  show_hook - Display current hook configuration
#
################################################################################
# Arguments:
#   1: hook_type - Type of hook to show
# Returns: 0 if hook exists, 1 if not configured

show_hook() {
    local hook_type="$1";
    local hook_var="SEMV_${hook_type^^}_BUMP_HOOK";
    local hook_command;
    
    # Check .semvrc first
    if [[ -f ".semvrc" ]]; then
        hook_command=$(grep "^${hook_var}=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
    fi
    
    if [[ -n "$hook_command" ]]; then
        info "$hook_type hook: $hook_command";
        return 0;
    else
        info "$hook_type hook: not configured";
        return 1;
    fi
}

################################################################################
#
#  set_hook - Configure hook command
#
################################################################################
# Arguments:
#   1: hook_type - Type of hook
#   2: command - Command to execute
# Returns: 0 on success, 1 on failure

set_hook() {
    local hook_type="$1";
    local command="$2";
    local hook_var="SEMV_${hook_type^^}_BUMP_HOOK";
    
    # Create or update .semvrc
    if [[ ! -f ".semvrc" ]]; then
        touch ".semvrc";
    fi
    
    # Remove existing hook setting
    if grep -q "^${hook_var}=" ".semvrc"; then
        sed -i.bak "/^${hook_var}=/d" ".semvrc";
        rm -f ".semvrc.bak" 2>/dev/null;
    fi
    
    # Add new hook setting
    echo "${hook_var}=\"${command}\"" >> ".semvrc";
    
    okay "Set $hook_type hook: $command";
    return 0;
}

################################################################################
#
#  create_hook_stub - Generate hook template script
#
################################################################################
# Arguments:
#   1: hook_type - Type of hook to create stub for
# Returns: 0 on success, 1 on failure

create_hook_stub() {
    local hook_type="$1";
    local stub_file="./hooks/${hook_type}_hook.sh";
    
    # Create hooks directory if it doesn't exist
    if [[ ! -d "./hooks" ]]; then
        mkdir -p "./hooks";
    fi
    
    # Create stub script
    cat > "$stub_file" <<EOF
#!/usr/bin/env bash
#
# SEMV $hook_type Hook - Auto-generated stub
# This script is executed after a $hook_type version bump
#

set -euo pipefail

# Hook arguments
VERSION="\$1"      # New version (e.g., v1.2.3)
PREV_VERSION="\$2" # Previous version (e.g., v1.2.2)

echo "Executing $hook_type hook for version: \$VERSION"

# Add your $hook_type bump automation here
# Examples:
# - Update documentation
# - Trigger CI/CD pipeline  
# - Send notifications
# - Update package registries
# - Run tests

echo "$hook_type hook completed successfully"
EOF
    
    chmod +x "$stub_file";
    okay "Created $hook_type hook stub: $stub_file";
    
    # Auto-configure in .semvrc
    set_hook "$hook_type" "$stub_file";
    
    return 0;
}

################################################################################
#
#  remove_hook - Remove hook configuration
#
################################################################################
# Arguments:
#   1: hook_type - Type of hook to remove
# Returns: 0 on success, 1 on failure

remove_hook() {
    local hook_type="$1";
    local hook_var="SEMV_${hook_type^^}_BUMP_HOOK";
    
    if [[ -f ".semvrc" ]]; then
        if grep -q "^${hook_var}=" ".semvrc"; then
            sed -i.bak "/^${hook_var}=/d" ".semvrc";
            rm -f ".semvrc.bak" 2>/dev/null;
            okay "Removed $hook_type hook configuration";
            return 0;
        fi
    fi
    
    warn "$hook_type hook was not configured";
    return 1;
}

################################################################################
#
#  execute_hook - Execute configured hook if present
#
################################################################################
# Arguments:
#   1: hook_type - Type of hook to execute
#   2: new_version - New version that was created
#   3: prev_version - Previous version
# Returns: 0 on success or no hook, 1 on hook failure

execute_hook() {
    local hook_type="$1";
    local new_version="$2";
    local prev_version="$3";
    local hook_var="SEMV_${hook_type^^}_BUMP_HOOK";
    local hook_command;
    
    # Check for hook configuration
    if [[ -f ".semvrc" ]]; then
        hook_command=$(grep "^${hook_var}=" ".semvrc" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'");
    fi
    
    if [[ -n "$hook_command" ]]; then
        info "Executing $hook_type hook: $hook_command";
        trace "Hook args: $new_version $prev_version";
        
        # Execute hook with version arguments
        if bash -c "$hook_command \"$new_version\" \"$prev_version\""; then
            okay "$hook_type hook completed successfully";
            return 0;
        else
            error "$hook_type hook failed";
            return 1;
        fi
    else
        trace "No $hook_type hook configured";
        return 0;
    fi
}
