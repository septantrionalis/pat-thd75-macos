# Repository maintenance

Read README.md and relevant scripts before changes. Preserve working USB
operation. Native Bluetooth reached CMS and exchanged FF/FQ, but its final
session-disconnect timeout remains unresolved. Do not claim a clean session.

Never expose, stage, or publish pat-packet.json, local.env, local INI files,
logs, or binaries. Use the examples. Keep credentials private and mode 0600.
Do not overwrite user gateway aliases. Do not redistribute AX25Toolkit source
or binaries without resolving its undeclared license; see THIRD_PARTY.md.
Keep the pinned revision and adaptation script in sync if updating upstream.

Run one bridge at a time; keep all listeners on loopback. The radio frequency
is manually selected. Validate configuration and script edits without RF.
Obtain current radio readiness before a requested RF connection test; avoid
repeated unanswered attempts. Do not make destructive system changes, delete
pairings, or reset global Bluetooth services without user approval.

Launchers must work from any current directory and avoid hardcoded personal
paths, callsigns, or Bluetooth addresses. local.env supplies private settings.
Preserve executable permissions. Update README.md for behavior changes.
