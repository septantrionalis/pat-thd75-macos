#!/bin/zsh
# Start both existing launchers in one Terminal; each owns its child processes.
unsetopt BG_NICE
cd "${0:A:h}" || exit 1
source ./scripts/common.zsh || exit 1
require_pat || exit 1
for launcher in ./start-bridge-bluetooth-native.command ./start-pat.command; do
    require_executable "$launcher" || exit 1
done
for port in 8000 8001 8080; do
    require_free_port "$port" || exit 1
done

bridge_pid=''
pat_launcher_pid=''
cleanup() {
    trap - EXIT INT TERM HUP
    print '\nStopping Pat and the Bluetooth bridge...'
    # Ask the launchers to run their cleanup traps; never kill unrelated services.
    [[ -n "$pat_launcher_pid" ]] && kill -TERM "$pat_launcher_pid" 2>/dev/null
    [[ -n "$pat_launcher_pid" ]] && wait "$pat_launcher_pid" 2>/dev/null
    [[ -n "$bridge_pid" ]] && kill -TERM "$bridge_pid" 2>/dev/null
    [[ -n "$bridge_pid" ]] && wait "$bridge_pid" 2>/dev/null
    return 0
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

print 'Starting the Bluetooth bridge...'
./start-bridge-bluetooth-native.command &
bridge_pid=$!
ready=0
for attempt in {1..60}; do
    if ! kill -0 "$bridge_pid" 2>/dev/null; then
        print -u2 'Bluetooth bridge exited before becoming ready. Pat was not started.'
        exit 1
    fi
    if /usr/bin/nc -z -G 1 127.0.0.1 8000 >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 1
done
if (( ! ready )); then
    print -u2 'Bluetooth bridge did not become ready within the startup window.'
    exit 1
fi

print 'Starting Pat. Its browser window will open when ready. Press Ctrl+C to stop everything.'
./start-pat.command &
pat_launcher_pid=$!
while true; do
    if ! kill -0 "$bridge_pid" 2>/dev/null; then
        print -u2 'Bluetooth bridge stopped; shutting down Pat.'
        exit 1
    fi
    if ! kill -0 "$pat_launcher_pid" 2>/dev/null; then
        wait "$pat_launcher_pid"
        exit $?
    fi
    sleep 1
done
