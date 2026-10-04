# TH-D75 packet Winlink on macOS

Local launchers for Pat Winlink and a Kenwood TH-D75 KISS TNC, using USB or
an experimental native Bluetooth connection. This is a community workaround,
not an official Pat, Kenwood, tncd, or AX25Toolkit distribution.

## Status

Tested with Pat 1.0.0, tncd 1.103-Beta (Apple Silicon), and macOS 26.6.2.
USB completed a packet Winlink mail check and clean disconnect on October 2,
2026. Native Bluetooth transmitted and received packets, reached CMS, and
exchanged FF/FQ on October 3, but Pat ultimately reported a disconnect timeout.
**A clean end-to-end Bluetooth session remains unverified.**

The native Bluetooth path bypasses `/dev/cu.TH-D75`, which opened successfully
in testing but produced no observed RF transmission:

```text
Pat → AGWPE 127.0.0.1:8000 → tncd → KISS TCP 127.0.0.1:8001
    → bt_kiss_bridge → Bluetooth RFCOMM channel 2 → TH-D75
```

The native launcher first disconnects only the selected radio's existing
Bluetooth link, retaining pairing. This cleared an existing-channel conflict
in testing. The toolkit is also locally adapted to use asynchronous RFCOMM
opening. We have not isolated whether that API change is necessary after
clearing the existing link.

## Dependencies

- macOS, Xcode Command Line Tools (`clang`, `make`), and Python 3.
- [Pat](https://getpat.io/), installed separately and configured for Winlink.
- [tncd](https://github.com/ben-kuhn/tncd/releases), downloaded separately.
  Our tested version is **1.103-Beta**. Choose the correct macOS architecture,
  verify the release checksum, extract `tncd` into this directory, and make it
  executable. Its macOS support is beta.
- For Bluetooth only: the separately downloaded AX25Toolkit source below.

Downloaded third-party source and binaries are deliberately excluded from Git.
No system service, driver installation, or global Bluetooth reset is required.

## Configure your private settings

From this directory, copy each example only if the local file does not exist:

```sh
cp -n pat-packet.example.json pat-packet.json
cp -n tncd.ini.example tncd.ini
cp -n tncd-bluetooth-native.ini.example tncd-bluetooth-native.ini
cp -n local.env.example local.env
chmod 600 pat-packet.json local.env
```

Existing users of this directory should **keep their existing local files**.

Edit:

- `pat-packet.json`: your callsign, Winlink password, Maidenhead locator, and
  optional favorite gateway aliases. The example callsigns are placeholders.
  You may instead copy your working Pat configuration and set `ax25.engine`
  to `agwpe` and `agwpe.addr` to `127.0.0.1:8000`, radio port `0`.
- Both local INI files: your callsign. For USB, set `device` to the current
  `/dev/cu.usbmodem*` device; it can change when the radio is reconnected.
- `local.env`: your paired TH-D75 Bluetooth address and optional default gateway
  alias. `PAT_BIN` can override the Pat executable path. This file is sourced
  as shell code; use only trusted local contents.

The launchers assume localhost ports **8000** (AGWPE), **8001** (native KISS),
and **8080** (Pat web UI). Keep the configurations at those ports unless you
also update the launchers. Nothing should listen on external interfaces.

**Never commit `pat-packet.json` or `local.env`.** They are ignored, along with
local INI files, logs, downloaded source, and binaries. Publish only examples.

## Build the native Bluetooth bridge

Upstream: https://github.com/solariun/AX25Toolkit

Pinned source revision: `943d1cc6e2313d339d13dc1fc317d6aea7930fee`.
At preparation time this source had no declared license file and GitHub showed
no license metadata. This repository does not bundle its source or binary.
Do not assume permission to redistribute either; clarify with its maintainer
before including them in your own releases. See `THIRD_PARTY.md`.

If `AX25Toolkit-main` already exists, preserve it: it may contain local changes.
For a fresh setup, download and unpack the pinned source yourself:

```sh
curl --fail --location \
  https://github.com/solariun/AX25Toolkit/archive/943d1cc6e2313d339d13dc1fc317d6aea7930fee.tar.gz \
  -o toolkit.tar.gz
tar -xzf toolkit.tar.gz
mv AX25Toolkit-943d1cc6e2313d339d13dc1fc317d6aea7930fee AX25Toolkit-main
./scripts/build-local.command
```

The build script applies the local adaptation and embeds Bluetooth usage
metadata. It also builds `reset-radio-link` from this repository's source.
It does not contact or transmit through the radio.

The adaptation changes `lib/bt_rfcomm_macos.mm`: asynchronous channel opening,
completion status, a 15-second wait while processing callbacks, cleanup on
failure, and diagnostic output. It does not modify KISS or AX.25 framing, or
`src/bt_kiss_bridge.cpp`. Inspect `scripts/patch-toolkit.py` for the changes.

## Run

### USB

1. Connect USB, set TH-D75 **Menu 983 = USB**, and enable **KISS 12**.
2. Tune the data band to your chosen 1200-baud packet gateway's frequency.
3. Close other applications using the radio, then run:

   ```sh
   ./start-bridge.command
   ```

### Bluetooth (experimental)

1. Pair the radio with macOS. Set **Menu 983 = Bluetooth** and **KISS 12**.
2. Tune the data band to the desired packet frequency. Close MacWinlink and
   other software using the radio. Stop the USB bridge.
3. Run:

   ```sh
   ./start-bridge-bluetooth-native.command
   ```

The launcher checks for occupied ports, releases the selected radio's old
link, and starts both bridge layers. Leave its Terminal window open.
Ctrl+C stops both layers. Do not run both USB and Bluetooth launchers together.

### Send and receive

In another Terminal window:

```sh
./start-pat.command
```

This checks for an AGWPE listener and opens http://localhost:8080 when Pat is
ready. The listener check does not prove radio connectivity. Ctrl+C stops Pat.

Compose a message and save it to the Outbox. In the connection dialog, select
a gateway and connect to send queued messages and download incoming mail.
Connect with an empty Outbox to check mail; downloaded messages appear in Inbox.

Use the RMS List's **Packet** filter and choose **Packet 1200** gateways.
The **AX.25** transport uses the configured AGWPE engine; **AX.25+agwpe** selects
it explicitly. VARA FM is a different mode and is not provided by this setup.
Keep aliases for favorites rather than entering every gateway in your area.

**Tune the radio manually before connecting.** Gateway selection and frequency
labels do not tune the TH-D75. Confirm the exact gateway callsign/SSID and mode.

For a command-line connection:

```sh
./connect-packet.command 'your-favorite-alias'
# Or an explicit packet destination:
./connect-packet.command 'ax25+agwpe:///N0CALL-10'
```

With no argument, the script uses `DEFAULT_GATEWAY` from `local.env`.
Keep attachments small on 1200-baud packet. USB serial speed is 9600 baud;
that is separate from the 1200-baud over-the-air speed.

## Troubleshooting and validation

- Opening a port or seeing “Connected” in Bluetooth settings does not prove
  RF transmission. Look for the radio TX indication and incoming AX.25 replies.
- Verify Menu 983 explicitly; enabling Bluetooth does not select the KISS route.
- The native path was tested on RFCOMM channel 2; verify the serial service if
  adapting this project to a different radio.
- Do not reset system Bluetooth services or delete pairings as routine fixes.
- Bluetooth session disconnect timeout remains unresolved. USB is the cleanly
  verified option. Do not infer successful mail delivery from a TX log.
- Preserve local source changes before updating AX25Toolkit or tncd.
- Validate without radio transmission:

  ```sh
  ./tncd check -c tncd.ini
  ./tncd check -c tncd-bluetooth-native.ini
  zsh -n start-pat.command
  zsh -n start-bridge-bluetooth-native.command
  ```

## Publishing this directory

Make this directory the repository root. Review `.gitignore` before staging.
It excludes actual credentials, radio addresses in `local.env`, third-party
source and binaries, archives, and logs. Do not use `git add -f` for those files.
Review `git diff --cached` before any commit or push. No repository, commit,
remote, or push is created automatically by these scripts.
