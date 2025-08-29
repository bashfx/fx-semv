#
# semv-colors.sh - Color and Glyph Definitions  
# semv-revision: 2.0.0-dev_1
# BashFX compliant color module using esc.sh standards
#

################################################################################
#
#  BashFX Standard Colors (from esc.sh)
#
################################################################################

# Core colors
readonly red=$'\x1B[38;5;197m';      # Was: $(tput setaf 202)
readonly green=$'\x1B[32m';          # Was: $(tput setaf 2)  
readonly blue=$'\x1B[36m';           # Was: $(tput setaf 12)
readonly orange=$'\x1B[38;5;214m';   # Was: $(tput setaf 214)
readonly yellow=$'\x1B[33m';         # Was: $(tput setaf 11)
readonly purple=$'\x1B[38;5;213m';   # Was: $(tput setaf 213)
readonly grey=$'\x1B[38;5;244m';     # Was: $(tput setaf 247)

# Extended colors
readonly blue2=$'\x1B[38;5;39m';
readonly cyan=$'\x1B[38;5;14m';
readonly white=$'\x1B[38;5;248m';
readonly white2=$'\x1B[38;5;15m';
readonly grey2=$'\x1B[38;5;240m';

# Control sequences
readonly revc=$'\x1B[7m';            # Reverse video - was: $(tput rev)
readonly bld=$'\x1B[1m';             # Bold
readonly x=$'\x1B[0m';               # Reset all attributes - was: $(tput sgr0)
readonly eol=$'\x1B[K';              # Erase to end of line

################################################################################
#
#  BashFX Standard Glyphs (from esc.sh)
#
################################################################################

# Status indicators
readonly pass=$'\u2713';             # ✓ - was: "\xE2\x9C\x93"
readonly fail=$'\u2715';             # ✕ - was: "${red}\xE2\x9C\x97"  
readonly delta=$'\u25B3';            # △ - was: "\xE2\x96\xB3"
readonly star=$'\u2605';             # ★ - was: "\xE2\x98\x85"

# Progress and activity  
readonly lambda=$'\u03BB';           # λ - was: "\xCE\xBB"
readonly idots=$'\u2026';            # … - was: "\xE2\x80\xA6"
readonly bolt=$'\u21AF';             # ↯ - was: "\xE2\x86\xAF"
readonly spark=$'\u27E1';            # ⟡ - was: "\xe2\x9f\xa1"

# Utility characters
readonly tab=$'\t';
readonly nl=$'\n';
readonly sp=' ';

################################################################################
#
#  SEMV-Specific Color Combinations
#
################################################################################

# Pre-composed colored glyphs for common patterns
readonly fail_red="${red}${fail}${x}";      # Red X for errors
readonly pass_green="${green}${pass}${x}";  # Green checkmark for success
readonly warn_orange="${orange}${delta}${x}"; # Orange triangle for warnings
readonly info_blue="${blue}${spark}${x}";   # Blue spark for info

################################################################################
#
#  Legacy Compatibility Mappings  
#
################################################################################

# Maintain compatibility with original semv variable names
# These can be removed in Phase 2 after function updates
readonly inv="$revc";                # Backwards compatibility for "inv"

# Mark colors as loaded (load guard pattern)
readonly SEMV_COLORS_LOADED=1;