#!/usr/bin/env bash

# git_sim.sh - A simulator for git commands for testing semv

# --- Helper Functions ---

# Find the root of the simulated repository by searching upwards for .gitsim
find_sim_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.gitsim" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

usage() {
    echo "usage: git_sim.sh <command> [<args>]"
    echo ""
    echo "These are common Git commands used in various situations:"
    echo ""
    echo "start a working area"
    echo "   init       Create an empty Git repository or reinitialize an existing one"
    echo ""
    echo "work on the current change"
    echo "   add        Add file contents to the index"
    echo "   status     Show the working tree status"
    echo ""
    echo "examine the history and state"
    echo "   log        Show commit logs"
    echo "   describe   Give an object a human readable name based on an available ref"
    echo "   diff       Show changes between commits, commit and working tree, etc"
    echo ""
    echo "grow, mark and tweak your common history"
    echo "   commit     Record changes to the repository"
    echo "   tag        Create, list, delete or verify a tag object signed with GPG"
    echo ""
    echo "custom simulator commands"
    echo "   noise      Create random files and stage them"
    echo "   help       Show this help message"
}

# --- Subcommands ---

# git init
cmd_init() {
    local SIM_DIR=".gitsim"
    local DATA_DIR="$SIM_DIR/.data"

    if [ -d "$DATA_DIR" ]; then
        echo "Reinitialized existing Git simulator repository in $(pwd)/$SIM_DIR/"
    else
        mkdir -p "$DATA_DIR"
        touch "$DATA_DIR/tags.txt"
        touch "$DATA_DIR/commits.txt"
        touch "$DATA_DIR/config"
        touch "$DATA_DIR/index"
        echo "main" > "$DATA_DIR/branch.txt"
        touch "$DATA_DIR/HEAD"
        echo "Initialized empty Git simulator repository in $(pwd)/$SIM_DIR/"
    fi

    if ! grep -q "^\.gitsim/$" .gitignore 2>/dev/null; then
        echo ".gitsim/" >> .gitignore
    fi
    return 0
}

# All other commands need the root path to be passed to them
cmd_config() {
    local STATE_FILE_CONFIG="$1"; shift
    local key="$1"
    local value="$2"
    if [ -n "$value" ]; then
        echo "$key=$value" >> "$STATE_FILE_CONFIG"
    else
        grep "^$key=" "$STATE_FILE_CONFIG" | cut -d'=' -f2
    fi
    return 0
}

cmd_add() {
    local STATE_FILE_INDEX="$1"
    local SIM_ROOT="$2"
    shift 2

    # The directory where we store git's internal state
    local GIT_DIR="$SIM_ROOT/.gitsim"

    if [[ "$1" == "." ]] || [[ "$1" == "--all" ]]; then
        # For 'add .', we find all files in the repo root, excluding the .gitsim directory
        > "$STATE_FILE_INDEX"

        # We must change to the SIM_ROOT to get relative paths correctly.
        (cd "$SIM_ROOT" && find . -type f -not -path "./.gitsim/*" -not -path "./.git/*" | sed 's|^\./||') >> "$STATE_FILE_INDEX"

    else
        for file in "$@"; do
            echo "$file" >> "$STATE_FILE_INDEX"
        done
    fi
    sort -u "$STATE_FILE_INDEX" -o "$STATE_FILE_INDEX"
    return 0
}

cmd_commit() {
    local STATE_FILE_COMMITS="$1"
    local STATE_FILE_HEAD="$2"
    local STATE_FILE_INDEX="$3"
    shift 3
    local message=""
    local allow_empty=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m) message="$2"; shift 2;;
            --allow-empty) allow_empty=true; shift;;
            *) shift;;
        esac
    done
    if [ -z "$message" ]; then return 1; fi

    if [ "$allow_empty" = false ] && ! [ -s "$STATE_FILE_INDEX" ]; then
        echo "nothing to commit, working tree clean" >&2
        return 1
    fi

    local commit_hash
    commit_hash=$( (echo "$message" ; date +%s) | shasum | head -c 7)
    echo "$commit_hash $message" >> "$STATE_FILE_COMMITS"
    echo "$commit_hash" > "$STATE_FILE_HEAD"
    > "$STATE_FILE_INDEX"
    return 0
}

cmd_tag() {
    local STATE_FILE_TAGS="$1"
    local STATE_FILE_HEAD="$2"
    shift 2
    if [[ $# -eq 0 ]]; then cat "$STATE_FILE_TAGS" | cut -d' ' -f1; return 0; fi
    local tag_name=""
    local message=""
    local delete_tag=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a) tag_name="$2"; shift 2;;
            -m) message="$2"; shift 2;;
            -d) delete_tag=true; tag_name="$2"; shift 2;;
            --list) cat "$STATE_FILE_TAGS" | cut -d' ' -f1; return 0;;
            *) return 1;;
        esac
    done
    if [[ "$delete_tag" = true ]]; then
        # Use sed to delete the line in-place. This is more robust than the grep/mv pattern.
        sed -i "/^$tag_name /d" "$STATE_FILE_TAGS"
        return 0
    fi
    if [ -n "$tag_name" ]; then
        # Check if tag already exists
        if grep -q "^$tag_name " "$STATE_FILE_TAGS"; then
            echo "fatal: tag '$tag_name' already exists" >&2
            return 128
        fi
        local commit_hash
        commit_hash=$(cat "$STATE_FILE_HEAD")
        if [ -z "$commit_hash" ]; then
            echo "fatal: Failed to create tag: HEAD does not point to a commit" >&2
            return 128
        fi
        echo "$tag_name $commit_hash $message" >> "$STATE_FILE_TAGS"
        return 0
    fi
}

cmd_log() {
    local STATE_FILE_COMMITS="$1"
    local STATE_FILE_TAGS="$2"
    shift 2

    # git log --pretty=format:"%s" "${tag}"..HEAD
    # This is a very specific implementation for semv's `since_last`
    if [[ "$1" == "--pretty=format:%s" ]]; then
        local range="$2"
        if [[ "$range" == *"..HEAD"* ]]; then
            local tag_name
            tag_name=$(echo "$range" | sed 's/\.\.HEAD//')

            local tag_commit_hash
            tag_commit_hash=$(grep "^$tag_name " "$STATE_FILE_TAGS" | head -n 1 | cut -d' ' -f2)

            if [ -n "$tag_commit_hash" ]; then
                # Find all commits after the tagged commit
                # The `sed` command prints all lines after the line with the matching hash
                sed -n "/$tag_commit_hash/,\$p" "$STATE_FILE_COMMITS" | tail -n +2 | awk '{$1=""; print $0}' | sed 's/^ //g'
                return 0
            fi
        fi
    fi

    # Default behavior: print all commit messages
    awk '{$1=""; print $0}' "$STATE_FILE_COMMITS" | sed 's/^ //g'
    return 0
}

cmd_describe() {
    local STATE_FILE_TAGS="$1"; shift
    cat "$STATE_FILE_TAGS" | cut -d' ' -f1 | sort -V | tail -n 1
    return 0
}

cmd_rev_parse() {
    local STATE_FILE_HEAD="$1"; shift
    case "$1" in
        --is-inside-work-tree) return 0;;
        --show-toplevel) find_sim_root; return 0;;
        HEAD) cat "$STATE_FILE_HEAD"; return 0;;
        *) return 1;;
    esac
}

cmd_branch() {
    local STATE_FILE_BRANCH="$1"; shift
    cat "$STATE_FILE_BRANCH"
    return 0
}

cmd_symbolic_ref() {
    shift # No state file needed, but still need to handle dispatcher args
    if [[ "$1" == "refs/remotes/origin/HEAD" ]]; then
        echo "refs/remotes/origin/main"
        return 0
    fi
    return 1
}

cmd_show() {
    shift # No state file needed
    if [[ "$1" == "-s" ]] && [[ "$2" == "--format=%ct" ]] && [[ "$3" == "HEAD" ]]; then
        date +%s
        return 0
    fi
    return 1
}

cmd_show_ref() {
    local STATE_FILE_TAGS="$1"; shift
    if [[ "$1" == "--tags" ]]; then
        cat "$STATE_FILE_TAGS" | cut -d' ' -f1
        return 0
    fi
    return 1
}

cmd_rev_list() {
    local STATE_FILE_COMMITS="$1"; shift
    if [[ "$1" == "--count" ]]; then
        wc -l < "$STATE_FILE_COMMITS" | tr -d ' '
        return 0
    fi
    return 1
}

cmd_status() {
    local STATE_FILE_INDEX="$1"; shift
    if [[ "$1" == "--porcelain" ]]; then
        if [ -s "$STATE_FILE_INDEX" ]; then
            sed 's/^/A  /' "$STATE_FILE_INDEX"
        fi
        return 0
    else
        # Human-readable output
        echo "On branch main"
        echo "Changes to be committed:"
        echo "  (use \"git restore --staged <file>...\" to unstage)"
        if [ -s "$STATE_FILE_INDEX" ]; then
            sed 's/^/\tnew file:   /' "$STATE_FILE_INDEX"
        else
            echo ""
            echo "nothing to commit, working tree clean"
        fi
        return 0
    fi
}

cmd_fetch() { return 0; }
cmd_push() { return 0; }

cmd_diff() {
    local STATE_FILE_INDEX="$1"; shift
    if [[ "$1" == "--exit-code" ]]; then
        if [ -s "$STATE_FILE_INDEX" ]; then return 1; else return 0; fi
    fi
    return 0
}

cmd_noise() {
    local SIM_ROOT="$1"
    local DATA_DIR="$2"
    shift 2
    local num_files=${1:-1}

    local names=("README" "script" "status" "main" "feature" "hotfix" "docs")
    local exts=(".md" ".fake" ".log" ".sh" ".txt" ".tmp")

    for i in $(seq 1 "$num_files"); do
        local rand_name=${names[$RANDOM % ${#names[@]}]}
        local rand_ext=${exts[$RANDOM % ${#exts[@]}]}
        local filename="${rand_name}_${i}${rand_ext}"

        # Create the file in the simulated workspace root
        head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 > "$SIM_ROOT/$filename"
        echo "$filename" >> "$DATA_DIR/index"
    done

    sort -u "$DATA_DIR/index" -o "$DATA_DIR/index"
    echo "Created and staged ${num_files} noisy file(s)."
    return 0
}


# --- Main Dispatcher ---

main() {
    local cmd="$1"

    if [[ -z "$cmd" ]] || [[ "$cmd" == "help" ]] || [[ "$cmd" == "--help" ]]; then
        usage
        return 0
    fi

    shift

    if [ "$cmd" == "init" ]; then
        cmd_init
        return $?
    fi

    local SIM_ROOT
    SIM_ROOT=$(find_sim_root)
    if [[ -z "$SIM_ROOT" ]]; then
        echo "fatal: not a git repository (or any of the parent directories): .gitsim" >&2
        return 128
    fi

    local SIM_DIR="$SIM_ROOT/.gitsim"
    local DATA_DIR="$SIM_DIR/.data"
    local STATE_FILE_CONFIG="$DATA_DIR/config"
    local STATE_FILE_TAGS="$DATA_DIR/tags.txt"
    local STATE_FILE_COMMITS="$DATA_DIR/commits.txt"
    local STATE_FILE_BRANCH="$DATA_DIR/branch.txt"
    local STATE_FILE_HEAD="$DATA_DIR/HEAD"
    local STATE_FILE_INDEX="$DATA_DIR/index"

    case "$cmd" in
        config)         cmd_config "$STATE_FILE_CONFIG" "$@";;
        add)            cmd_add "$STATE_FILE_INDEX" "$SIM_ROOT" "$@";;
        commit)         cmd_commit "$STATE_FILE_COMMITS" "$STATE_FILE_HEAD" "$STATE_FILE_INDEX" "$@";;
        tag)            cmd_tag "$STATE_FILE_TAGS" "$STATE_FILE_HEAD" "$@";;
        log)            cmd_log "$STATE_FILE_COMMITS" "$STATE_FILE_TAGS" "$@";;
        describe)       cmd_describe "$STATE_FILE_TAGS" "$@";;
        rev-parse)      cmd_rev_parse "$STATE_FILE_HEAD" "$@";;
        branch)         cmd_branch "$STATE_FILE_BRANCH" "$@";;
        symbolic-ref)   cmd_symbolic_ref "$@";;
        show)           cmd_show "$@";;
        show-ref)       cmd_show_ref "$STATE_FILE_TAGS" "$@";;
        rev-list)       cmd_rev_list "$STATE_FILE_COMMITS" "$@";;
        status)         cmd_status "$STATE_FILE_INDEX" "$@";;
        fetch)          cmd_fetch "$@";;
        diff)           cmd_diff "$STATE_FILE_INDEX" "$@";;
        push)           cmd_push "$@";;
        noise)          cmd_noise "$SIM_ROOT" "$DATA_DIR" "$@";;
        *)
            echo "git_simulator: unknown command '$cmd'" >&2
            usage
            return 1
            ;;
    esac
}

main "$@"
