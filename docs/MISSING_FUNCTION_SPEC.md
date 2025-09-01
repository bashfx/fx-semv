# SEMV Missing Function Implementation Specification

## Summary
The `can` command is mapped in dispatch but `do_can_semver()` function is missing from parts/13_commands.sh.

## Location
- **Dispatch Reference**: `parts/15_dispatch.sh:47` - `can) func_name="do_can_semver";;`
- **Missing Function**: `do_can_semver()` should be in `parts/13_commands.sh`
- **Insert After**: Line 677 (after `do_auto()` function ends)

## Function Specification

```bash
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
```

## Dependencies
Uses existing functions:
- `_is_git_repo` - from git ops
- `has_semver` - from version checking
- `is_not_staged` - from git status
- `detect_project_type` - from project detection
- `info`, `okay`, `warn`, `error` - from printers

## Testing Command
After implementation: `./semv.sh can`

## Story Points: 1
Simple function using existing utilities, straightforward implementation.

---
*Documentation by KEEPER for Tommy's implementation*