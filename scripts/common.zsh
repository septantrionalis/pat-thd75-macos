# Sourced by launchers after changing to the project directory.
[[ ! -f ./local.env ]] || source ./local.env || return 1
require_file() {
    [[ -f "$1" ]] && return 0
    print -u2 "Missing $1. Follow README.md to create local configuration."
    return 1
}
require_executable() {
    [[ -x "$1" ]] && return 0
    print -u2 "Missing executable $1. Follow README.md build/install instructions."
    return 1
}
require_free_port() {
    if /usr/bin/nc -z -G 2 127.0.0.1 "$1" >/dev/null 2>&1; then
        print -u2 "Port $1 is already in use. Stop the existing service first."
        return 1
    fi
}
require_pat() {
    if [[ -z "$PAT_BIN" ]]; then
        PAT_BIN=$(command -v pat)
        [[ -n "$PAT_BIN" ]] || PAT_BIN=/usr/local/bin/pat
    fi
    require_executable "$PAT_BIN" || return 1
    require_file ./pat-packet.json
}
