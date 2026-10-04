#!/usr/bin/env python3
"""Apply this project's small macOS adaptation to a user-supplied toolkit copy."""
from pathlib import Path
import plistlib

root = Path(__file__).resolve().parent.parent / 'AX25Toolkit-main'
p = root / 'lib/bt_rfcomm_macos.mm'
s = p.read_text()
if 'openRFCOMMChannelAsync:' not in s:
    changes = [
        ('std::atomic<bool> connected{false};', 'std::atomic<bool> connected{false};\n    std::atomic<bool> open_done{false};\n    IOReturn open_status = kIOReturnError;'),
        ('    (void)rfcommChannel;\n    if (error != kIOReturnSuccess)', '    (void)rfcommChannel;\n    _handle->open_status = error;\n    _handle->open_done = true;\n    if (error != kIOReturnSuccess)'),
        ('openRFCOMMChannelSync:&rfcommChannel', 'openRFCOMMChannelAsync:&rfcommChannel'),
        ('        if (ret != kIOReturnSuccess || !rfcommChannel) {', '''        std::cerr << "  Async request status: 0x" << std::hex << ret << std::dec << "; channel allocated: " << (rfcommChannel != nil) << "\\n";
        if (ret == kIOReturnSuccess && rfcommChannel) {
            auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(15);
            while (!handle->open_done && std::chrono::steady_clock::now() < deadline) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, true);
            }
            ret = handle->open_done ? handle->open_status : kIOReturnTimeout;
        }
        if (ret != kIOReturnSuccess || !rfcommChannel) {
            [rfcommChannel setDelegate:nil];
            [rfcommChannel closeChannel];'''),
    ]
    for before, after in changes:
        if s.count(before) != 1:
            raise SystemExit('Unexpected source version; refusing to modify it.')
        s = s.replace(before, after, 1)
    p.write_text(s)
else:
    for marker in ['open_done', 'open_status', '[rfcommChannel setDelegate:nil]', 'seconds(15)']:
        if marker not in s:
            raise SystemExit('Unrecognized existing async implementation; inspect manually.')
    print('Local asynchronous patch already present.')
(root / 'BluetoothInfo.plist').write_bytes(plistlib.dumps({
    'CFBundleIdentifier': 'local.thd75.bluetooth-kiss',
    'CFBundleName': 'Bluetooth KISS Bridge',
    'CFBundleVersion': '1',
    'NSBluetoothAlwaysUsageDescription': 'Connect to a paired radio for KISS packet data.',
    'NSBluetoothPeripheralUsageDescription': 'Connect to a paired radio for KISS packet data.',
}))
