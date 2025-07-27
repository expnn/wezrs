# This script provides wrapper functions for `trzsz` to integrate with
# WezTerm's file transfer user variables (SetUserVar).
# It should be sourced by your shell's startup file (e.g., ~/.bashrc or ~/.zshrc)
#
# To use it:
#   source /path/to/wezrs.sh

# Ensure the script is sourced, not executed, and only in interactive shells.
# Also check for required commands: base64 and trzsz.
if ! [ -t 1 ]; then
    # When sourced (not executed), return success (0) to avoid breaking other init scripts
    return 0
fi

# Check for required commands and report missing ones
missing_commands=()
for cmd in base64 trzsz jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing_commands+=("$cmd")
    fi
done

if [ ${#missing_commands[@]} -gt 0 ]; then
    echo "wezrs: Missing required commands: ${missing_commands[*]}. Please install them to enable file transfer functionality." >&2
    return 0
fi

# Memoize the base64 version string to avoid repeated calls.
# This helps determine the correct flags for encoding.
__wezrs_get_base64_version() {
    if [ -z "$WEZRS_BASE64_VERSION" ]; then
        # We capture stderr because some versions (like on macOS) print version to stderr.
        WEZRS_BASE64_VERSION=$(base64 --version 2>&1)
        export WEZRS_BASE64_VERSION
    fi
}

# Base64 encode stdin, handling GNU vs other versions.
__wezrs_b64_encode() {
    __wezrs_get_base64_version
    # GNU base64 uses -w0 to disable line wrapping. Other versions (like macOS)
    # do this by default.
    if [[ "$WEZRS_BASE64_VERSION" == *"GNU"* ]]; then
        base64 -w0
    else
        base64
    fi
}

# Display help for the original command (tsz/trz) but with the alias name.
# Returns 0 if help was shown, 1 otherwise.
__wezrs_show_help() {
    local original_cmd="$1"
    local alias_cmd="$2"
    shift 2
    local show_help=false
    for arg in "$@"; do
        if [[ "$arg" == "-h" ]] || [[ "$arg" == "--help" ]]; then
            show_help=true
            break
        fi
    done

    if [ "$show_help" = true ]; then
        # Fish's `&|` redirects both stdout and stderr. In bash, this is `2>&1 |`.
        "$original_cmd" -h 2>&1 | sed "1s/$original_cmd/$alias_cmd/"
        return 0 # Success
    else
        return 1 # Failure
    fi
}

# Construct the JSON payload and send the OSC 1337 escape sequence.
__wezrs_set_usr_var() {
    # The first argument is the command (tsz or trz).
    local cmd_name="$1"
    shift

    # Create a JSON array of the command and its arguments.
    local cmd_json
    cmd_json=$(jq -n -c '$ARGS.positional' --args -- "$cmd_name" "$@")

    # Create the final JSON payload.
    local args_json
    args_json=$(jq -n -c \
        --arg user "$USER" \
        --arg host "$(hostname)" \
        --argjson cmd "$cmd_json" \
        --arg cwd "$PWD" \
        '{user: $user, host: $host, cmd: $cmd, cwd: $cwd}')

    # Base64 encode the payload.
    local b64_args
    b64_args=$(echo "$args_json" | __wezrs_b64_encode)

    # Print the escape sequence, handling tmux passthrough if necessary.
    if [ -z "$TMUX" ]; then
        printf "\033]1337;SetUserVar=wez_file_transfer=%s\007" "$b64_args"
    else
        # See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
        printf "\033Ptmux;\033\033]1337;SetUserVar=wez_file_transfer=%s\007\033\\" "$b64_args"
    fi
}

# wezs: Download (send) files from the remote server to the local machine.
# Wrapper for `tsz`.
wezs() {
    if ! command -v jq >/dev/null; then
        echo "wezs: 'jq' command is required but not found." >&2
        return 1
    fi
    # If help is requested, show it and stop. Otherwise, set user var and run command.
    if ! __wezrs_show_help tsz wezs "$@"; then
        __wezrs_set_usr_var tsz "$@"
    fi
}

# wezr: Upload (receive) files on the remote server from the local machine.
# Wrapper for `trz`.
wezr() {
    if ! command -v jq >/dev/null; then
        echo "wezr: 'jq' command is required but not found." >&2
        return 1
    fi
    # If help is requested, show it and stop. Otherwise, set user var and run command.
    if ! __wezrs_show_help trz wezr "$@"; then
        __wezrs_set_usr_var trz "$@"
    fi
}
