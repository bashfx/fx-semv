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

# XDG+ Compliance paths (canonical *_HOME variables)
readonly SEMV_ETC_HOME="${XDG_ETC:-$HOME/.local/etc}/fx/semv";
readonly SEMV_DATA_HOME="${XDG_DATA:-$HOME/.local/data}/fx/semv";
readonly SEMV_LIB_HOME="${XDG_LIB:-$HOME/.local/lib}/fx/semv";

# Back-compatibility aliases
readonly SEMV_CONFIG="$SEMV_ETC_HOME";   # legacy naming
readonly SEMV_ETC="$SEMV_ETC_HOME";      # transitional alias
readonly SEMV_DATA="$SEMV_DATA_HOME";    # legacy naming

# RC file under ETC
readonly SEMV_RC="${SEMV_ETC_HOME}/.semv.rc";

# Commit message label conventions
# Commit label scheme (SEMV v2.0)
# Major:    major, breaking, api
# Minor:    feat, feature, add, minor
# Patch:    fix, patch, bug, hotfix, up
# Dev:      dev
readonly SEMV_MAJ_LABEL="(major|breaking|api)";
readonly SEMV_FEAT_LABEL="(feat|feature|add|minor)";  
readonly SEMV_FIX_LABEL="(fix|patch|bug|hotfix|up)";
readonly SEMV_DEV_LABEL="dev";

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
opt_debug=0;       # 0=enabled, 1=disabled (default off=1)
opt_trace=0;       # 0=enabled, 1=disabled (default off=1)  
opt_quiet=0;       # 0=enabled, 1=disabled (default off=1 - show messages)
opt_force=0;       # 0=enabled, 1=disabled (default off=1)
opt_yes=0;         # 0=enabled, 1=disabled (default off=1)
opt_dev=0;         # 0=enabled, 1=disabled (default off=1)

# SEMV-specific option states
opt_dev_note=1;    # 0=enabled, 1=disabled (default off=1)
opt_build_dir=1;   # 0=enabled, 1=disabled (default off=1)
opt_no_cursor=1;   # 0=enabled, 1=disabled (default off=1)
opt_auto=0;        # 0=enabled (auto-mode default on to avoid prompts), 1=disabled

################################################################################
#
#  Environment Variable Support
#
################################################################################

# Support NO_BUILD_CURSOR environment variable
if [[ "${NO_BUILD_CURSOR:-}" == "1" ]] || [[ "${NO_BUILD_CURSOR:-}" == "true" ]]; then
    opt_no_cursor=0;
fi

# Support QUIET_MODE, DEBUG_MODE, TRACE_MODE from BashFX standards (0=true)
if [[ -n "${QUIET_MODE+x}" ]]; then
    if [[ "${QUIET_MODE}" == "0" || "${QUIET_MODE}" == "true" ]]; then
        opt_quiet=0;
    else
        opt_quiet=1;
    fi
fi

if [[ -n "${DEBUG_MODE+x}" ]]; then
    if [[ "${DEBUG_MODE}" == "0" || "${DEBUG_MODE}" == "true" ]]; then
        opt_debug=0;
    else
        opt_debug=1;
    fi
fi

if [[ -n "${TRACE_MODE+x}" ]]; then
    if [[ "${TRACE_MODE}" == "0" || "${TRACE_MODE}" == "true" ]]; then
        opt_trace=0;
    else
        opt_trace=1;
    fi
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
    
    ret=0;
    # Ensure ETC/DATA exist
    if [[ ! -d "$SEMV_ETC_HOME" ]]; then
        mkdir -p "$SEMV_ETC_HOME" 2>/dev/null || ret=1;
    fi
    
    if [[ ! -d "$SEMV_DATA_HOME" ]]; then
        mkdir -p "$SEMV_DATA_HOME" 2>/dev/null || ret=1;
    fi
    
    return "$ret";
}

# Mark config as loaded (load guard pattern)
readonly SEMV_CONFIG_LOADED=1;
