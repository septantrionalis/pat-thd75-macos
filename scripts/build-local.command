#!/bin/zsh
set -eu
cd "${0:A:h:h}"
[[ -f AX25Toolkit-main/lib/bt_rfcomm_macos.mm ]] || {
    print -u2 'Download the pinned toolkit source as described in README.md first.'
    exit 1
}
python3 scripts/patch-toolkit.py
clang -fobjc-arc -framework Foundation -framework IOBluetooth reset-radio-link.m -o reset-radio-link
cd AX25Toolkit-main
# Force rebuild so an existing binary cannot silently miss the embedded plist.
make -B bt_kiss_bridge CXXFLAGS='-std=c++11 -O2 -Wall -Wextra -Wpedantic -Ilib -Wl,-sectcreate,__TEXT,__info_plist,BluetoothInfo.plist'
