#!/usr/bin/env bash
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
    info "Configuration: $SEMV_CONFIG";
    
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
    if [[ -d "$SEMV_CONFIG" ]]; then
        if __confirm "Remove configuration directory ($SEMV_CONFIG)"; then
            if rm -rf "$SEMV_CONFIG"; then
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
    if [[ -d "$SEMV_CONFIG" ]]; then
        local backup_dir="${SEMV_CONFIG}.backup.$(date +%s)";
        if cp -r "$SEMV_CONFIG" "$backup_dir"; then
            info "Backed up existing configuration to: $backup_dir";
        else
            warn "Failed to backup existing configuration";
        fi
    fi
    
    # Remove current configuration
    if [[ -d "$SEMV_CONFIG" ]]; then
        if ! rm -rf "$SEMV_CONFIG"; then
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
    
    # Check configuration
    if [[ -d "$SEMV_CONFIG" ]]; then
        okay "Configuration: $SEMV_CONFIG ✓";
    else
        warn "Configuration: $SEMV_CONFIG ✗";
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
    local config_file="$SEMV_CONFIG/config";
    local ret=1;
    
    if ! mkdir -p "$SEMV_CONFIG"; then
        return 1;
    fi
    
    # Create main configuration file
    cat > "$config_file" << 'EOF'
# SEMV Configuration File
# semv-revision: 2.0.0-dev_1

# Commit label configuration
SEMV_MAJ_LABEL="brk"
SEMV_FEAT_LABEL="feat"
SEMV_FIX_LABEL="fix"
SEMV_DEV_LABEL="dev"

# Build configuration
SEMV_MIN_BUILD=1000

# Default options
DEFAULT_DEBUG=1
DEFAULT_TRACE=1
DEFAULT_QUIET=1
DEFAULT_FORCE=1
DEFAULT_YES=1
DEFAULT_DEV_NOTE=1
DEFAULT_BUILD_DIR=1
DEFAULT_NO_CURSOR=1

# Environment overrides
NO_BUILD_CURSOR=${NO_BUILD_CURSOR:-}
QUIET_MODE=${QUIET_MODE:-}
DEBUG_MODE=${DEBUG_MODE:-}
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
SEMV_HOME=$SEMV_HOME
SEMV_CONFIG=$SEMV_CONFIG
SEMV_DATA=$SEMV_DATA
EOF

    if [[ -f "$SEMV_RC" ]]; then
        ret=0;
    fi
    
    return "$ret";
}

# Mark lifecycle as loaded (load guard pattern)
readonly SEMV_LIFECYCLE_LOADED=1;