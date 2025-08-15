#!/usr/bin/env bash
#
# semv-config.sh - Configuration and Constants
# semv-revision: 2.0.0-dev_1
# BashFX compliant configuration module
#

################################################################################
#
#  SEMV Configuration & Constants
#
################################################################################

# Self-reference variables
readonly SEMV_PATH="${BASH_SOURCE[0]}";
readonly SEMV_EXEC="$0";

# XDG+ Compliance paths
readonly SEMV_HOME="${XDG_HOME:-$HOME/.local}/fx/semv";
readonly SEMV_CONFIG="${XDG_ETC:-$HOME/.local/etc}/fx/semv";
readonly SEMV_DATA="${XDG_DATA:-$HOME/.local/data}/fx/semv";
readonly SEMV_RC="${SEMV_HOME}/.semv.rc";

# Commit message label conventions
readonly SEMV_MAJ_LABEL="brk";    # Breaking changes -> Major bump
readonly SEMV_FEAT_LABEL="feat";  # New features -> Minor bump  
readonly SEMV_FIX_LABEL="fix";    # Bug fixes -> Patch bump
readonly SEMV_DEV_LABEL="dev";    # Development notes -> Dev build

# Build system constants
readonly SEMV_MIN_BUILD=1000;     # Minimum build number floor

# Terminal setup
export TERM=xterm-256color;

################################################################################
#
#  Default Option States
#
################################################################################

# Standard BashFX flag variables (set by options())
opt_debug=1;       # 0=enabled, 1=disabled (default off)
opt_trace=1;       # 0=enabled, 1=disabled (default off)  
opt_quiet=1;       # 0=enabled, 1=disabled (default off)
opt_force=1;       # 0=enabled, 1=disabled (default off)
opt_yes=1;         # 0=enabled, 1=disabled (default off)
opt_dev=1;         # 0=enabled, 1=disabled (default off)

# SEMV-specific option states
opt_dev_note=1;    # 0=enabled, 1=disabled (default off)
opt_build_dir=1;   # 0=enabled, 1=disabled (default off)
opt_no_cursor=1;   # 0=enabled, 1=disabled (default off)

################################################################################
#
#  Environment Variable Support
#
################################################################################

# Support NO_BUILD_CURSOR environment variable
if [[ "${NO_BUILD_CURSOR:-}" == "1" ]] || [[ "${NO_BUILD_CURSOR:-}" == "true" ]]; then
    opt_no_cursor=0;
fi

# Support QUIET_MODE, DEBUG_MODE from BashFX standards
if [[ "${QUIET_MODE:-}" == "1" ]] || [[ "${QUIET_MODE:-}" == "true" ]]; then
    opt_quiet=0;
fi

if [[ "${DEBUG_MODE:-}" == "1" ]] || [[ "${DEBUG_MODE:-}" == "true" ]]; then
    opt_debug=0;
fi

################################################################################
#
#  Configuration Validation
#
################################################################################

# Ensure XDG+ directories exist if we're in install mode
# (This will be called by lifecycle functions)
_ensure_xdg_paths() {
    local ret=1;
    
    if [[ ! -d "$SEMV_HOME" ]]; then
        mkdir -p "$SEMV_HOME" 2>/dev/null && ret=0;
    else
        ret=0;
    fi
    
    if [[ ! -d "$SEMV_CONFIG" ]]; then
        mkdir -p "$SEMV_CONFIG" 2>/dev/null || ret=1;
    fi
    
    if [[ ! -d "$SEMV_DATA" ]]; then
        mkdir -p "$SEMV_DATA" 2>/dev/null || ret=1;
    fi
    
    return "$ret";
}

# Mark config as loaded (load guard pattern)
readonly SEMV_CONFIG_LOADED=1;