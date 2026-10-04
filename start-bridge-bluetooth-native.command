#!/bin/zsh
cd "${0:A:h}" || exit 1
source ./scripts/common.zsh || exit 1
if [[ ! "$BLUETOOTH_ADDRESS" =~ '^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$' ]]; then
    print -u2 'Set BLUETOOTH_ADDRESS in local.env to your paired radio address.'
    exit 1
fi
require_file ./tncd-bluetooth-native.ini || exit 1
bridge_bin=./bin/bt_kiss_bridge
[[ -x "$bridge_bin" ]] || bridge_bin=./AX25Toolkit-main/bin/bt_kiss_bridge
for program in ./reset-radio-link ./tncd "$bridge_bin"; do
    require_executable "$program" || exit 1
done
for port in 8000 8001; do
    if /usr/bin/nc -z -G 2 127.0.0.1 "$port" >/dev/null 2>&1; then
        print -u2 "Port $port is in use. Stop the existing bridge before starting this one."
        exit 1
    fi
done
# Release only this radio's existing link; pairing is retained.
./reset-radio-link "$BLUETOOTH_ADDRESS" || exit 1
native_pid=''
tnc_pid=''
cleanup() {
    trap - EXIT INT TERM
    [[ -n "$tnc_pid" ]] && kill -INT "$tnc_pid" 2>/dev/null
    [[ -n "$native_pid" ]] && kill -INT "$native_pid" 2>/dev/null
    [[ -n "$tnc_pid" ]] && wait "$tnc_pid" 2>/dev/null
    [[ -n "$native_pid" ]] && wait "$native_pid" 2>/dev/null
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
"$bridge_bin" --bt --device "$BLUETOOTH_ADDRESS" --channel 2 --server-host 127.0.0.1 --server-port 8001 --monitor &
native_pid=$!
ready=0
for attempt in {1..30}; do
    kill -0 "$native_pid" 2>/dev/null || break
    if /usr/bin/nc -z -G 1 127.0.0.1 8001 >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 1
done
if (( ! ready )); then
    print -u2 'Native Bluetooth bridge did not become ready.'
    exit 1
fi
./tncd -c tncd-bluetooth-native.ini -v &
tnc_pid=$!
wait "$tnc_pid"
