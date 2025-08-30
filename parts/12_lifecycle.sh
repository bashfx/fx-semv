#
# semv-lifecycle.sh - Installation and Lifecycle Management
# semv-revision: 2.0.0-dev_1
# BashFX compliant lifecycle functions
#

################################################################################
#
#  Installation Functions
#
################################################################################

################################################################################
#
#  do_install - Install semv to BashFX system
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: ret, semv_bin, semv_lib
# Stream Usage: Messages to stderr

do_install() {
    local ret=1;
    local semv_bin="${XDG_BIN:-$HOME/.local/bin}/semv";
    local semv_lib="${XDG_LIB:-$HOME/.local/lib}/fx/semv";
    
    info "Installing SEMV to BashFX system...";
    
    # Ensure XDG+ directories exist
    if ! _ensure_xdg_paths; then
        error "Failed to create XDG+ directories";
        return 1;
    fi

    # Migrate RC from legacy location if present
    __migrate_rc_if_needed || true
    
    # Create semv lib directory
    if ! mkdir -p "$semv_lib"; then
        error "Failed to create semv library directory: $semv_lib";
        return 1;
    fi
    
    # Copy script to lib location
    if ! cp "$SEMV_PATH" "$semv_lib/semv.sh"; then
        error "Failed to copy semv script to library";
        return 1;
    fi
    
    # Create symlink in bin
    if ! ln -sf "$semv_lib/semv.sh" "$semv_bin"; then
        error "Failed to create binary symlink";
        return 1;
    fi
    
    # Make executable
    if ! chmod +x "$semv_lib/semv.sh"; then
        error "Failed to make script executable";
        return 1;
    fi
    
    # Create initial configuration
    if ! __create_default_config; then
        warn "Failed to create default configuration";
    fi
    
    # Create RC file for session state
    if ! __create_rc_file; then
        warn "Failed to create RC file";
    fi
    
    okay "SEMV installed successfully";
    info "Binary: $semv_bin";
    info "Library: $semv_lib";
    info "ETC (config): $SEMV_ETC_HOME";
    
    ret=0;
    return "$ret";
}

################################################################################
#
#  do_uninstall - Remove semv from BashFX system
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: ret, semv_bin, semv_lib
# Stream Usage: Messages to stderr

do_uninstall() {
    local ret=1;
    local semv_bin="${XDG_BIN:-$HOME/.local/bin}/semv";
    local semv_lib="${XDG_LIB:-$HOME/.local/lib}/fx/semv";
    
    info "Uninstalling SEMV from BashFX system...";
    
    # Remove symlink
    if [[ -L "$semv_bin" ]]; then
        if rm "$semv_bin"; then
            okay "Removed binary symlink: $semv_bin";
        else
            error "Failed to remove binary symlink";
            return 1;
        fi
    fi
    
    # Remove library directory
    if [[ -d "$semv_lib" ]]; then
        if rm -rf "$semv_lib"; then
            okay "Removed library directory: $semv_lib";
        else
            error "Failed to remove library directory";
            return 1;
        fi
    fi
    
    # Ask about configuration removal
    if [[ -d "$SEMV_ETC_HOME" ]]; then
        if __confirm "Remove configuration directory ($SEMV_ETC_HOME)"; then
            if rm -rf "$SEMV_ETC_HOME"; then
                okay "Removed configuration directory";
            else
                warn "Failed to remove configuration directory";
            fi
        else
            info "Keeping configuration directory";
        fi
    fi
    
    # Ask about data removal
    if [[ -d "$SEMV_DATA" ]]; then
        if __confirm "Remove data directory ($SEMV_DATA)"; then
            if rm -rf "$SEMV_DATA"; then
                okay "Removed data directory";
            else
                warn "Failed to remove data directory";
            fi
        else
            info "Keeping data directory";
        fi
    fi
    
    okay "SEMV uninstalled successfully";
    ret=0;
    return "$ret";
}

################################################################################
#
#  do_reset - Reset configuration to defaults
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: ret
# Stream Usage: Messages to stderr

do_reset() {
    local ret=1;
    
    info "Resetting SEMV configuration to defaults...";
    
    # Backup existing configuration
    if [[ -d "$SEMV_ETC_HOME" ]]; then
        local backup_dir="${SEMV_ETC_HOME}.backup.$(date +%s)";
        if cp -r "$SEMV_ETC_HOME" "$backup_dir"; then
            info "Backed up existing configuration to: $backup_dir";
        else
            warn "Failed to backup existing configuration";
        fi
    fi
    
    # Remove current configuration
    if [[ -d "$SEMV_ETC_HOME" ]]; then
        if ! rm -rf "$SEMV_ETC_HOME"; then
            error "Failed to remove current configuration";
            return 1;
        fi
    fi
    
    # Recreate default configuration
    if ! _ensure_xdg_paths; then
        error "Failed to recreate configuration directories";
        return 1;
    fi
    
    if ! __create_default_config; then
        error "Failed to create default configuration";
        return 1;
    fi
    
    if ! __create_rc_file; then
        error "Failed to create RC file";
        return 1;
    fi
    
    okay "Configuration reset successfully";
    ret=0;
    return "$ret";
}

################################################################################
#
#  do_status - Show installation and configuration status
#
################################################################################
# Returns: 0 always
# Local Variables: semv_bin, semv_lib, status
# Stream Usage: Messages to stderr

do_status() {
    local semv_bin="${XDG_BIN:-$HOME/.local/bin}/semv";
    local semv_lib="${XDG_LIB:-$HOME/.local/lib}/fx/semv";
    local status;
    
    info "SEMV Installation Status:";
    # Attempt RC migration passively during status
    __migrate_rc_if_needed || true
    
    # Check binary symlink
    if [[ -L "$semv_bin" ]] && [[ -x "$semv_bin" ]]; then
        okay "Binary: $semv_bin ✓";
    else
        warn "Binary: $semv_bin ✗";
    fi
    
    # Check library
    if [[ -f "$semv_lib/semv.sh" ]] && [[ -x "$semv_lib/semv.sh" ]]; then
        okay "Library: $semv_lib ✓";
    else
        warn "Library: $semv_lib ✗";
    fi
    
    # Check configuration (ETC)
    if [[ -d "$SEMV_ETC_HOME" ]]; then
        okay "ETC (config): $SEMV_ETC_HOME ✓";
    else
        warn "ETC (config): $SEMV_ETC_HOME ✗";
    fi
    
    # Check data directory
    if [[ -d "$SEMV_DATA" ]]; then
        okay "Data: $SEMV_DATA ✓";
    else
        warn "Data: $SEMV_DATA ✗";
    fi
    
    # Check RC file
    if [[ -f "$SEMV_RC" ]]; then
        okay "RC File: $SEMV_RC ✓";
    else
        warn "RC File: $SEMV_RC ✗";
    fi
    
    return 0;
}

################################################################################
#
#  Configuration Helper Functions
#
################################################################################

################################################################################
#
#  __create_default_config - Create default configuration files
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: config_file, ret
# Stream Usage: Messages to stderr

__create_default_config() {
    local config_file="$SEMV_ETC_HOME/config";
    local ret=1;
    
    if ! mkdir -p "$SEMV_ETC_HOME"; then
        return 1;
    fi
    
    # Create main configuration file
    cat > "$config_file" << 'EOF'
# SEMV Configuration File
# semv-revision: 2.0.0-dev_1

# Commit label configuration (SEMV v2.0)
SEMV_MAJ_LABEL="(major|breaking|api)"
SEMV_FEAT_LABEL="(feat|feature|add|minor)"
SEMV_FIX_LABEL="(fix|patch|bug|hotfix|up)"
SEMV_DEV_LABEL="dev"

# Build configuration
SEMV_MIN_BUILD=1000

# Environment overrides
NO_BUILD_CURSOR=${NO_BUILD_CURSOR:-}
QUIET_MODE=${QUIET_MODE:-}
DEBUG_MODE=${DEBUG_MODE:-}
TRACE_MODE=${TRACE_MODE:-}
EOF

    if [[ -f "$config_file" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  __create_rc_file - Create RC file for session state
#
################################################################################
# Returns: 0 on success, 1 on failure
# Local Variables: ret
# Stream Usage: Messages to stderr

__create_rc_file() {
    local ret=1;
    
    # Ensure any legacy RC is migrated before (re)creation
    __migrate_rc_if_needed || true
    
    if ! mkdir -p "$(dirname "$SEMV_RC")"; then
        return 1;
    fi
    
    # Create RC file with current state
    cat > "$SEMV_RC" << EOF
# SEMV Session State
# Generated: $(date)
# semv-revision: 2.0.0-dev_1

SEMV_INSTALLED=1
SEMV_INSTALL_DATE=$(date +%s)
SEMV_VERSION=2.0.0-dev_1
SEMV_ETC_HOME=$SEMV_ETC_HOME
SEMV_CONFIG=$SEMV_CONFIG
SEMV_DATA_HOME=$SEMV_DATA_HOME
EOF

    if [[ -f "$SEMV_RC" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

################################################################################
#
#  __migrate_rc_if_needed - Move legacy RC to SEMV_ETC if found
#
################################################################################
# Returns: 0 on success or nothing to do, 1 on failure

__migrate_rc_if_needed() {
    local legacy_rc="${XDG_HOME:-$HOME/.local}/fx/semv/.semv.rc";
    local target_rc="$SEMV_RC";
    local target_dir
    target_dir="$(dirname "$target_rc")"
    
    if [[ -f "$legacy_rc" ]] && [[ ! -f "$target_rc" ]]; then
        mkdir -p "$target_dir" 2>/dev/null || return 1
        if mv "$legacy_rc" "$target_rc"; then
            okay "Migrated RC to: $target_rc";
            return 0;
        else
            warn "Failed to migrate RC from legacy location";
            return 1;
        fi
    fi
    return 0;
}

# Mark lifecycle as loaded (load guard pattern)
readonly SEMV_LIFECYCLE_LOADED=1;
