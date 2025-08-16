#!/usr/bin/env bash

# git_simulator.sh - A simulator for git commands for testing semv

# The directory to store our fake git state
SIM_DIR=".gitsim"
STATE_FILE_CONFIG="$SIM_DIR/config"
STATE_FILE_TAGS="$SIM_DIR/tags.txt"
STATE_FILE_COMMITS="$SIM_DIR/commits.txt"
STATE_FILE_BRANCH="$SIM_DIR/branch.txt"
STATE_FILE_HEAD="$SIM_DIR/HEAD"
STATE_FILE_INDEX="$SIM_DIR/index"

# --- Helper Functions ---
is_repo() {
    [ -d "$SIM_DIR" ]
}

# --- Subcommands ---

# git init
cmd_init() {
    if is_repo; then
        echo "Reinitialized existing Git simulator repository in $(pwd)/$SIM_DIR/"
    else
        mkdir "$SIM_DIR"
        touch "$STATE_FILE_TAGS"
        touch "$STATE_FILE_COMMITS"
        touch "$STATE_FILE_CONFIG"
        touch "$STATE_FILE_INDEX"
        echo "main" > "$STATE_FILE_BRANCH"
        # HEAD will store the last commit hash, or be empty
        touch "$STATE_FILE_HEAD"
        echo "Initialized empty Git simulator repository in $(pwd)/$SIM_DIR/"
    fi

    # Ensure the .gitsim directory is ignored by the real git
    if ! grep -q "^\.gitsim/$" .gitignore 2>/dev/null; then
        echo ".gitsim/" >> .gitignore
    fi

    return 0
}

# git config
cmd_config() {
    local key="$1"
    local value="$2"
    if [ -n "$value" ]; then
        # Set config
        echo "$key=$value" >> "$STATE_FILE_CONFIG"
    else
        # Get config
        grep "^$key=" "$STATE_FILE_CONFIG" | cut -d'=' -f2
    fi
    return 0
}

# git add
cmd_add() {
    # Add specified files to the index.
    # A dot '.' means add everything in the current directory.
    if [[ "$1" == "." ]] || [[ "$1" == "--all" ]]; then
        # Find all files except those in .gitsim
        find . -type f -not -path "./.gitsim/*" >> "$STATE_FILE_INDEX"
    else
        for file in "$@"; do
            echo "$file" >> "$STATE_FILE_INDEX"
        done
    fi
    # Ensure uniqueness
    sort -u "$STATE_FILE_INDEX" -o "$STATE_FILE_INDEX"
    return 0
}

# git commit
cmd_commit() {
    local message=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m)
                message="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -z "$message" ]; then
        echo "Aborting commit due to empty commit message." >&2
        return 1
    fi

    # Create a fake commit hash and store the message
    local commit_hash
    commit_hash=$(date +%s | shasum | head -c 7)
    echo "$commit_hash $message" >> "$STATE_FILE_COMMITS"
    echo "$commit_hash" > "$STATE_FILE_HEAD"
    # Clear the index after commit
    > "$STATE_FILE_INDEX"
    return 0
}

# git tag
cmd_tag() {
    # If no arguments, list tags
    if [[ $# -eq 0 ]]; then
        cat "$STATE_FILE_TAGS" | cut -d' ' -f1
        return 0
    fi

    local tag_name=""
    local message=""
    local delete_tag=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a)
                tag_name="$2"
                shift 2
                ;;
            -m)
                message="$2"
                shift 2
                ;;
            -d)
                delete_tag=true
                tag_name="$2"
                shift 2
                ;;
            --list)
                cat "$STATE_FILE_TAGS" | cut -d' ' -f1
                return 0
                ;;
            *)
                echo "git_simulator: unknown argument to tag: $1" >&2
                return 1
                ;;
        esac
    done

    if [[ "$delete_tag" = true ]]; then
        # Deleting a tag
        grep -v "^$tag_name " "$STATE_FILE_TAGS" > "$STATE_FILE_TAGS.tmp"
        mv "$STATE_FILE_TAGS.tmp" "$STATE_FILE_TAGS"
        echo "Deleted tag '$tag_name' (if it existed)"
        return 0
    fi

    if [ -n "$tag_name" ]; then
        # Creating a tag
        echo "$tag_name $message" >> "$STATE_FILE_TAGS"
        return 0
    fi
}

# git log
cmd_log() {
    # This is a simplified log command. It just shows the commit messages.
    # It doesn't yet handle ranges like "tag..HEAD".
    awk '{$1=""; print $0}' "$STATE_FILE_COMMITS" | sed 's/^ //g'
    return 0
}

# git describe
cmd_describe() {
    # Simplified: returns the last tag from the tags file.
    cat "$STATE_FILE_TAGS" | cut -d' ' -f1 | sort -V | tail -n 1
    return 0
}

# git rev-parse
cmd_rev_parse() {
    case "$1" in
        --is-inside-work-tree)
            if is_repo; then return 0; else return 1; fi
            ;;
        --show-toplevel)
            echo "."
            return 0
            ;;
        HEAD)
            cat "$STATE_FILE_HEAD"
            return 0
            ;;
        *)
            echo "git_simulator: unknown argument to rev-parse: $1" >&2
            return 1
            ;;
    esac
}

# git branch
cmd_branch() {
    case "$1" in
        --show-current)
            cat "$STATE_FILE_BRANCH"
            return 0
            ;;
        *)
            # For now, just show the current branch
            cat "$STATE_FILE_BRANCH"
            return 0
            ;;
    esac
}

# git symbolic-ref
cmd_symbolic_ref() {
    # Hardcoded for semv's which_main() function
    if [[ "$1" == "refs/remotes/origin/HEAD" ]]; then
        echo "refs/remotes/origin/main"
        return 0
    fi
    return 1
}

# git show
cmd_show() {
    # Simplified for getting commit timestamp
    if [[ "$1" == "-s" ]] && [[ "$2" == "--format=%ct" ]] && [[ "$3" == "HEAD" ]]; then
        date +%s
        return 0
    fi
    return 1
}

# git show-ref
cmd_show_ref() {
    if [[ "$1" == "--tags" ]]; then
        # Just list the tags, similar to 'git tag'
        cat "$STATE_FILE_TAGS" | cut -d' ' -f1
        return 0
    fi
    return 1
}

# git rev-list
cmd_rev_list() {
    if [[ "$2" == "--count" ]]; then
        wc -l < "$STATE_FILE_COMMITS" | tr -d ' '
        return 0
    fi
    return 1
}

# git status
cmd_status() {
    if [[ "$1" == "--porcelain" ]]; then
        # Return staged files from the index
        if [ -s "$STATE_FILE_INDEX" ]; then
            sed 's/^/A  /' "$STATE_FILE_INDEX"
        fi
        return 0
    fi
    return 1
}

# git fetch
cmd_fetch() {
    # No-op
    return 0
}

# git diff
cmd_diff() {
    # Check for staged changes.
    if [[ "$1" == "--exit-code" ]]; then
        if [ -s "$STATE_FILE_INDEX" ]; then
            return 1 # 1 means there are differences
        else
            return 0 # 0 means no differences
        fi
    fi
    # Default diff behavior (not implemented)
    return 0
}

# git push
cmd_push() {
    # No-op
    return 0
}


# --- Main Dispatcher ---

main() {
    if ! is_repo && [ "$1" != "init" ]; then
        echo "fatal: not a git repository (or any of the parent directories): .gitsim" >&2
        return 128
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        init)           cmd_init "$@";;
        config)         cmd_config "$@";;
        add)            cmd_add "$@";;
        commit)         cmd_commit "$@";;
        tag)            cmd_tag "$@";;
        log)            cmd_log "$@";;
        describe)       cmd_describe "$@";;
        rev-parse)      cmd_rev_parse "$@";;
        branch)         cmd_branch "$@";;
        symbolic-ref)   cmd_symbolic_ref "$@";;
        show)           cmd_show "$@";;
        show-ref)       cmd_show_ref "$@";;
        rev-list)       cmd_rev_list "$@";;
        status)         cmd_status "$@";;
        fetch)          cmd_fetch "$@";;
        diff)           cmd_diff "$@";;
        push)           cmd_push "$@";;
        *)
            echo "git_simulator: unknown command '$cmd'" >&2
            return 1
            ;;
    esac
}

main "$@"
