# Prebuilt Bluetooth bridge

`bt_kiss_bridge` is a Mach-O ARM64 (Apple Silicon) executable built locally on
macOS 26.6.2 using Apple Command Line Tools. It is not Developer ID signed or
notarized; compatibility with other macOS versions has not been established.

Upstream: https://github.com/solariun/AX25Toolkit
Source revision: 943d1cc6e2313d339d13dc1fc317d6aea7930fee
Local modifications: scripts/patch-toolkit.py, including asynchronous RFCOMM
opening, completion handling, failed-open cleanup, and diagnostics. Bluetooth
usage metadata is embedded during the build. See scripts/build-local.command.

SHA256SUMS records this executable's SHA-256 digest (paths relative to the
repository root). The binary contains no project login configuration; radio
address and connection arguments are supplied by the launcher.

Upstream has no declared license at the time of inclusion. This binary was
added at the repository owner's explicit request; that does not establish
permission from upstream or grant redistribution rights. See THIRD_PARTY.md.

Bluetooth RF traffic and CMS access were demonstrated with this approach,
but the final Winlink session-disconnect timeout remains unresolved. This is
an experimental workaround, not a fully validated release.
