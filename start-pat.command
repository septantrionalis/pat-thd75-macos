#!/bin/zsh
cd "${0:A:h}" || exit 1
source ./scripts/common.zsh || exit 1
require_pat || exit 1

if ! /usr/bin/nc -z -G 2 127.0.0.1 8000 >/dev/null 2>&1; then
    print -u2 "Pat was not started: the packet bridge is not listening on 127.0.0.1:8000."
    print -u2 "Run start-bridge.command (USB) or start-bridge-bluetooth-native.command first."
    exit 1
fi

if /usr/bin/nc -z -G 2 127.0.0.1 8080 >/dev/null 2>&1; then
    print -u2 "Pat was not started: port 8080 is already in use."
    exit 1
fi

"$PAT_BIN" --config "$PWD/pat-packet.json" http &
pat_pid=$!
cleanup() {
    trap - EXIT INT TERM
    if kill -0 "$pat_pid" 2>/dev/null; then
        kill -INT "$pat_pid" 2>/dev/null
        wait "$pat_pid" 2>/dev/null
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

ready=0
for attempt in {1..30}; do
    if ! kill -0 "$pat_pid" 2>/dev/null; then
        wait "$pat_pid"
        exit $?
    fi
    if /usr/bin/curl --fail --silent --max-time 1 http://localhost:8080/ >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 1
done

if (( ready )); then
    /usr/bin/open http://localhost:8080 || print -u2 "Open http://localhost:8080 manually."
else
    print -u2 "Pat has not become ready yet. Open http://localhost:8080 manually when it is ready."
fi

# Keep the Terminal session attached; Ctrl+C stops Pat.
wait "$pat_pid"
